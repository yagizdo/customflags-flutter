import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'constants/api_endpoints.dart';
import 'core/exceptions.dart';
import 'core/models/flag_model.dart';
import 'core/models/flag_response_model.dart';
import 'customflag_config.dart';

class ApiClient {
  final CustomFlagConfig config;

  late final Dio _dio;

  static const String _authHeader = 'X-Api-Key';
  static const String _acceptHeader = 'Accept';
  static const String _applicationJson = 'application/json';

  ApiClient({required this.config, @visibleForTesting String? baseUrl}) {
    _dio = _buildDioClient(baseUrl);
  }

  Dio _buildDioClient(String? baseUrl) {
    final dio = Dio(config.baseOptions)
      ..options.baseUrl = baseUrl ?? kCustomFlagBaseUrl
      ..options.headers[_authHeader] = config.apiKey
      ..options.headers[_acceptHeader] = _applicationJson
      ..options.followRedirects = true
      ..options.maxRedirects = 5;

    return dio;
  }

  Future<List<Flag>> fetchAllFlags({required String userId}) async {
    try {
      final response = await _dio.get(
        kCustomFlagFlagsEndpoint,
        queryParameters: {kCustomFlagFlagsUserQueryParam: userId},
      );
      final flagResponse =
          FlagResponse.fromJson(response.data as Map<String, dynamic>);
      return flagResponse.flags;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  CustomFlagApiException _mapDioException(DioException e) {
    return CustomFlagApiException(
      statusCode: e.response?.statusCode,
      body: e.response?.data?.toString(),
      message: e.message ?? 'Request failed',
    );
  }

  void close() => _dio.close();
}
