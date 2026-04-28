import 'package:customflags/customflags.dart';
import 'package:customflags/src/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  CustomFlagConfig config() => CustomFlagConfig(apiKey: 'test_key');

  group('CustomFlagClient — guards before identity is set', () {
    test('[CustomFlagClient] fetchAllFlags throws ConfigurationException when setIdentity has not been called', () {
      final client = CustomFlagClient(config: config());
      expect(client.fetchAllFlags, throwsA(isA<ConfigurationException>()));
    });

    test('[CustomFlagClient] getFlag throws ConfigurationException when setIdentity has not been called', () {
      final client = CustomFlagClient(config: config());
      expect(() => client.getFlag('any'), throwsA(isA<ConfigurationException>()));
    });
  });

  group('CustomFlagClient — argument validation', () {
    test('[CustomFlagClient] getFlag throws ArgumentError when featureKey is empty', () {
      final client = CustomFlagClient(config: config());
      client.setIdentity(const Identity(identifier: 'u'));
      expect(() => client.getFlag(''), throwsA(isA<ArgumentError>()));
    });

    test('[CustomFlagClient] setIdentity throws ConfigurationException when identifier is empty', () {
      final client = CustomFlagClient(config: config());
      expect(
        () => client.setIdentity(const Identity(identifier: '')),
        throwsA(isA<ConfigurationException>()),
      );
    });
  });

  group('CustomFlagClient — identity replacement and cancellation', () {
    test('[CustomFlagClient] setIdentity replacement causes the next fetch to send the new identifier', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final client = CustomFlagClient(config: config(), apiClient: api);

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {'flags': <String, dynamic>{}}),
        queryParameters: {'user': 'user_b'},
      );

      client.setIdentity(const Identity(identifier: 'user_a'));
      client.setIdentity(const Identity(identifier: 'user_b'));
      final flags = await client.fetchAllFlags();
      expect(flags, isEmpty);
    });

    test('[CustomFlagClient] setIdentity cancels an in-flight fetchAllFlags', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final client = CustomFlagClient(config: config(), apiClient: api);

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(
          200,
          {'flags': <String, dynamic>{}},
          delay: const Duration(seconds: 5),
        ),
        queryParameters: {'user': 'user_a'},
      );

      client.setIdentity(const Identity(identifier: 'user_a'));
      final pending = client.fetchAllFlags();

      client.setIdentity(const Identity(identifier: 'user_b'));

      await expectLater(
        pending,
        throwsA(predicate((e) =>
            e is CustomFlagApiException ||
            (e is DioException && CancelToken.isCancel(e)))),
      );
    });
  });
}
