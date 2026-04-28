import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'constants/api_endpoints.dart';
import 'core/exceptions.dart';
import 'core/models/flag_model.dart';
import 'core/models/flag_response_model.dart';
import 'core/models/identity.dart';
import 'customflag_config.dart';

class ApiClient {
  final CustomFlagConfig config;

  late final Dio _dio;

  static const String _authHeader = 'X-Api-Key';
  static const String _acceptHeader = 'Accept';
  static const String _applicationJson = 'application/json';

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

      if (flags.length != 1) {
        throw CustomFlagApiException(
          statusCode: response.statusCode,
          message: 'Expected exactly 1 flag for "$featureKey", got ${flags.length} '
              '(keys: ${flags.map((f) => f.key).join(", ")})',
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

  void close() => _dio.close();
}
