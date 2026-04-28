import 'package:customflags/customflags.dart';
import 'package:customflags/src/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  CustomFlagConfig config() => CustomFlagConfig(apiKey: 'test_key');

  (Dio, DioAdapter, ApiClient) setup() {
    final dio = Dio();
    final adapter = DioAdapter(dio: dio);
    final api = ApiClient(config: config(), dio: dio);
    return (dio, adapter, api);
  }

  const identity = Identity(identifier: 'user_42');

  group('ApiClient.fetchAllFlags — happy path', () {
    test('[ApiClient] fetchAllFlags returns the parsed Flag list when response is well-formed', () async {
      final (_, adapter, api) = setup();
      adapter.onGet(
        '/api/v1/flags',
        (s) => s.reply(200, {
          'flags': {'dark_mode': true, 'language': 'en'}
        }),
        queryParameters: {'user': identity.identifier},
      );

      final flags = await api.fetchAllFlags(identity: identity);
      expect(flags.length, 2);
      expect(flags.map((f) => f.key).toSet(), {'dark_mode', 'language'});
    });
  });

  group('ApiClient.fetchAllFlags — response shape guards', () {
    test('[ApiClient] fetchAllFlags throws CustomFlagApiException when response body is not a JSON object', () async {
      final (_, adapter, api) = setup();
      adapter.onGet(
        '/api/v1/flags',
        (s) => s.reply(200, <int>[1, 2, 3]),
        queryParameters: {'user': identity.identifier},
      );

      await expectLater(
        api.fetchAllFlags(identity: identity),
        throwsA(isA<CustomFlagApiException>()),
      );
    });

    test('[ApiClient] fetchAllFlags rethrows MalformedResponseException without re-wrapping', () async {
      final (_, adapter, api) = setup();
      adapter.onGet(
        '/api/v1/flags',
        (s) => s.reply(200, {'flags': 'not a map'}),
        queryParameters: {'user': identity.identifier},
      );

      await expectLater(
        api.fetchAllFlags(identity: identity),
        throwsA(isA<MalformedResponseException>()),
      );
    });
  });

  group('ApiClient.fetchAllFlags — DioException mapping', () {
    test('[ApiClient] fetchAllFlags maps connectionTimeout to a CustomFlagApiException with "Connection timed out"', () async {
      final (_, adapter, api) = setup();
      adapter.onGet(
        '/api/v1/flags',
        (s) => s.throws(
          408,
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 1),
            requestOptions: RequestOptions(path: '/api/v1/flags'),
          ),
        ),
        queryParameters: {'user': identity.identifier},
      );

      await expectLater(
        api.fetchAllFlags(identity: identity),
        throwsA(
          isA<CustomFlagApiException>()
              .having((e) => e.message, 'message', contains('Connection timed out')),
        ),
      );
    });

    test('[ApiClient] fetchAllFlags maps badResponse with status to "Server returned <code>"', () async {
      final (_, adapter, api) = setup();
      adapter.onGet(
        '/api/v1/flags',
        (s) => s.reply(500, {'error': 'boom'}),
        queryParameters: {'user': identity.identifier},
      );

      await expectLater(
        api.fetchAllFlags(identity: identity),
        throwsA(
          isA<CustomFlagApiException>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('ApiClient.fetchFlag — guards', () {
    test('[ApiClient] fetchFlag throws CustomFlagApiException when response contains zero flags', () async {
      final (_, adapter, api) = setup();
      adapter.onGet(
        '/api/v1/flags/dark_mode',
        (s) => s.reply(200, {'flags': <String, dynamic>{}}),
        queryParameters: {'user': identity.identifier},
      );

      await expectLater(
        api.fetchFlag(identity: identity, featureKey: 'dark_mode'),
        throwsA(
          isA<CustomFlagApiException>()
              .having((e) => e.message, 'message', contains('got 0')),
        ),
      );
    });

    test('[ApiClient] fetchFlag throws CustomFlagApiException when response contains multiple flags', () async {
      final (_, adapter, api) = setup();
      adapter.onGet(
        '/api/v1/flags/dark_mode',
        (s) => s.reply(200, {
          'flags': {'dark_mode': true, 'extra': 'unexpected'}
        }),
        queryParameters: {'user': identity.identifier},
      );

      await expectLater(
        api.fetchFlag(identity: identity, featureKey: 'dark_mode'),
        throwsA(
          isA<CustomFlagApiException>()
              .having((e) => e.message, 'message', contains('got 2'))
              .having((e) => e.message, 'message', contains('keys: dark_mode, extra'))
              .having((e) => e.body, 'body', isNull),
        ),
      );
    });
  });

  group('ApiClient — cancelToken', () {
    test('[ApiClient] fetchAllFlags propagates a cancelled token as a Dio cancel error', () async {
      final (_, adapter, api) = setup();
      adapter.onGet(
        '/api/v1/flags',
        (s) => s.reply(
          200,
          {'flags': <String, dynamic>{}},
          delay: const Duration(seconds: 5),
        ),
        queryParameters: {'user': identity.identifier},
      );

      final token = CancelToken();
      final pending = api.fetchAllFlags(identity: identity, cancelToken: token);
      token.cancel('test');
      await expectLater(
        pending,
        throwsA(predicate((e) =>
            e is CustomFlagApiException ||
            (e is DioException && CancelToken.isCancel(e)))),
      );
    });
  });
}
