import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'constants/api_endpoints.dart';
import 'constants/regex_patterns.dart';
import 'core/exceptions.dart';
import 'core/models/flag_model.dart';
import 'core/models/flag_response_model.dart';
import 'core/models/identity.dart';
import 'customflag_config.dart';

/// Low-level HTTP transport for the CustomFlags backend.
///
/// Wraps [Dio] with the authentication header, timeout configuration,
/// and response-to-model mapping. Not exported from the package —
/// consumers interact through [CustomFlagClient] instead.
///
/// Throws [CustomFlagApiException] on network or HTTP errors and
/// [MalformedResponseException] when the response shape is invalid.
class ApiClient {
  /// The [CustomFlagConfig] used to configure timeouts and the
  /// authentication header.
  final CustomFlagConfig config;

  late final Dio _dio;

  static const String _authHeader = 'X-Api-Key';
  static const String _acceptHeader = 'Accept';
  static const String _applicationJson = 'application/json';

  /// Creates an HTTP client configured from [config].
  ///
  /// Builds a [Dio] instance eagerly with the API key header,
  /// timeouts, and redirect policy. Inject a custom [dio] or
  /// [baseUrl] in tests to avoid hitting the real backend.
  ApiClient({
    required this.config,
    @visibleForTesting String? baseUrl,
    @visibleForTesting Dio? dio,
  }) {
    _dio = dio ?? _buildDioClient(baseUrl);
  }

  Dio _buildDioClient(String? baseUrl) {
    final dio = Dio(BaseOptions(
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: kIsWeb ? null : config.sendTimeout,
    ))
      ..options.baseUrl = baseUrl ?? kCustomFlagBaseUrl
      ..options.headers[_authHeader] = config.apiKey
      ..options.headers[_acceptHeader] = _applicationJson
      ..options.followRedirects = false
      ..options.maxRedirects = 0;

    return dio;
  }

  /// Fetches every flag assigned to [identity] from the backend.
  ///
  /// Returns the parsed [Flag] list from the `flags` envelope.
  /// Pass a [cancelToken] to abort the request (e.g. on identity
  /// switch). Throws [CustomFlagApiException] on network/HTTP errors
  /// and [MalformedResponseException] when the response shape is
  /// invalid.
  Future<List<Flag>> fetchAllFlags({
    required Identity identity,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        kCustomFlagFlagsEndpoint,
        queryParameters: {kCustomFlagFlagsUserQueryParam: identity.identifier},
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw CustomFlagApiException(
          statusCode: response.statusCode,
          body: data?.toString(),
          message: 'Expected JSON object, got ${data.runtimeType}',
        );
      }

      return FlagResponse.fromJson(data).flags;
    } on CustomFlagsException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Fetches the single flag identified by [featureKey] for [identity].
  ///
  /// Returns `Flag(key: featureKey, value: null)` when the backend
  /// omits the key (wire convention: absent = off). Throws
  /// [MalformedResponseException] when the response contains more
  /// than one flag for a single-key query.
  Future<Flag> fetchFlag({
    required Identity identity,
    required String featureKey,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        kCustomFlagSingleFlagEndpoint(featureKey),
        queryParameters: {kCustomFlagFlagsUserQueryParam: identity.identifier},
        cancelToken: cancelToken,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw CustomFlagApiException(
          statusCode: response.statusCode,
          body: data?.toString(),
          message: 'Expected JSON object, got ${data.runtimeType}',
        );
      }
      final flags = FlagResponse.fromJson(data).flags;

      if (flags.isEmpty) {
        return Flag(key: featureKey, value: null);
      }
      if (flags.length > 1) {
        final sanitizedKeys = flags
            .map((f) => f.key.replaceAll(kLogInjectionControlCharsPattern, ' '))
            .join(', ');
        throw MalformedResponseException(
          message: 'Expected at most 1 flag for "$featureKey", got ${flags.length} '
              '(keys: $sanitizedKeys)',
        );
      }

      return flags.first;
    } on CustomFlagsException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  CustomFlagApiException _mapDioException(DioException e) {
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout => 'Connection timed out',
      DioExceptionType.receiveTimeout => 'Response timed out',
      DioExceptionType.sendTimeout => 'Send timed out',
      DioExceptionType.connectionError => 'Could not reach server',
      DioExceptionType.badResponse => 'Server returned ${e.response?.statusCode}',
      _ => e.message ?? 'Request failed',
    };

    return CustomFlagApiException(
      statusCode: e.response?.statusCode,
      body: e.response?.data?.toString(),
      message: message,
    );
  }

  /// Closes the underlying [Dio] client and releases its resources.
  void close() => _dio.close();
}
