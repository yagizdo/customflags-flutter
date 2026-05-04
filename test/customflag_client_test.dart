import 'package:customflags/customflags.dart';
import 'package:customflags/src/api_client.dart';
import 'package:customflags/src/cache/flag_cache.dart';
import 'package:customflags/src/cache/flag_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  CustomFlagConfig config() => CustomFlagConfig(apiKey: 'test_key');

  group('CustomFlagClient — guards before identity is set', () {
    test('[CustomFlagClient] fetchAllFlags throws ConfigurationException when setIdentity has not been called', () {
      final client = CustomFlagClient(config: config());
      expect(client.fetchAllFlags, throwsA(isA<ConfigurationException>()));
    });
  });

  group('CustomFlagClient — argument validation', () {
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

  group('CustomFlagClient — init()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('[CustomFlagClient] init loads flags from network and populates cache', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final storage = FlagStorage();
      final cache = FlagCache(storage: storage);
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true, 'theme': 'blue'},
        }),
        queryParameters: {'user': 'user_42'},
      );

      client.setIdentity(const Identity(identifier: 'user_42'));
      await client.init();

      expect(client.getFlag('dark_mode').getBool(), true);
      expect(client.getFlag('theme').getString(), 'blue');
    });

    test('[CustomFlagClient] init throws on network failure but preserves disk cache', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final storage = FlagStorage();
      await storage.write('user_42', {
        'cached_flag': const Flag(key: 'cached_flag', value: 'from_disk'),
      });
      final cache = FlagCache(storage: storage);
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.throws(
          500,
          DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
        ),
        queryParameters: {'user': 'user_42'},
      );

      client.setIdentity(const Identity(identifier: 'user_42'));
      await expectLater(client.init, throwsA(isA<CustomFlagApiException>()));

      expect(client.getFlag('cached_flag').getString(), 'from_disk');
    });

    test('[CustomFlagClient] init throws when no disk cache and network fails', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.throws(
          500,
          DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
        ),
        queryParameters: {'user': 'user_42'},
      );

      client.setIdentity(const Identity(identifier: 'user_42'));
      await expectLater(client.init, throwsA(isA<CustomFlagApiException>()));

      expect(client.getFlag('any_key').value, isNull);
    });

    test('[CustomFlagClient] init throws ConfigurationException when identity not set', () {
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        cache: cache,
      );

      expect(client.init, throwsA(isA<ConfigurationException>()));
    });
  });

  group('CustomFlagClient — sync reads', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('[CustomFlagClient] getFlag returns Flag with null value before init', () {
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(config: config(), cache: cache);
      client.setIdentity(const Identity(identifier: 'u'));

      final flag = client.getFlag('anything');
      expect(flag.key, 'anything');
      expect(flag.value, isNull);
    });

    test('[CustomFlagClient] getAllFlags returns empty map before init', () {
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(config: config(), cache: cache);
      client.setIdentity(const Identity(identifier: 'u'));

      expect(client.getAllFlags(), isEmpty);
    });

    test('[CustomFlagClient] getFlag is synchronous after init', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true},
        }),
        queryParameters: {'user': 'u'},
      );

      client.setIdentity(const Identity(identifier: 'u'));
      await client.init();

      final flag = client.getFlag('dark_mode');
      expect(flag.getBool(), true);
    });
  });

  group('CustomFlagClient — refresh()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('[CustomFlagClient] refresh updates cache with fresh data', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true},
        }),
        queryParameters: {'user': 'u'},
      );

      client.setIdentity(const Identity(identifier: 'u'));
      await client.init();
      expect(client.getFlag('dark_mode').getBool(), true);

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': false},
        }),
        queryParameters: {'user': 'u'},
      );

      await client.refresh();
      expect(client.getFlag('dark_mode').getBool(), false);
    });

    test('[CustomFlagClient] refresh throws on network failure but preserves old cache', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true},
        }),
        queryParameters: {'user': 'u'},
      );

      client.setIdentity(const Identity(identifier: 'u'));
      await client.init();

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.throws(
          500,
          DioException(requestOptions: RequestOptions(), type: DioExceptionType.connectionError),
        ),
        queryParameters: {'user': 'u'},
      );

      await expectLater(client.refresh, throwsA(isA<CustomFlagApiException>()));
      expect(client.getFlag('dark_mode').getBool(), true);
    });

    test('[CustomFlagClient] refresh throws ConfigurationException when identity not set', () {
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(config: config(), cache: cache);

      expect(client.refresh, throwsA(isA<ConfigurationException>()));
    });
  });

  group('CustomFlagClient — flagStream', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('[CustomFlagClient] flagStream emits after init', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true},
        }),
        queryParameters: {'user': 'u'},
      );

      final emissions = <Map<String, Flag>>[];
      client.flagStream.listen(emissions.add);

      client.setIdentity(const Identity(identifier: 'u'));
      await client.init();

      await Future<void>.delayed(Duration.zero);
      expect(emissions.isNotEmpty, isTrue);
      expect(emissions.last['dark_mode']!.getBool(), true);
    });

    test('[CustomFlagClient] flagStream emits after refresh', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true},
        }),
        queryParameters: {'user': 'u'},
      );

      client.setIdentity(const Identity(identifier: 'u'));
      await client.init();

      final emissions = <Map<String, Flag>>[];
      client.flagStream.listen(emissions.add);

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': false},
        }),
        queryParameters: {'user': 'u'},
      );

      await client.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(emissions.isNotEmpty, isTrue);
      expect(emissions.last['dark_mode']!.getBool(), false);
    });
  });

  group('CustomFlagClient — setIdentity clears cache', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('[CustomFlagClient] setIdentity clears the in-memory cache', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true},
        }),
        queryParameters: {'user': 'user_a'},
      );

      client.setIdentity(const Identity(identifier: 'user_a'));
      await client.init();
      expect(client.getFlag('dark_mode').getBool(), true);

      client.setIdentity(const Identity(identifier: 'user_b'));
      expect(client.getFlag('dark_mode').value, isNull);
    });
  });

  group('CustomFlagClient — clearCache()', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('[CustomFlagClient] clearCache throws ConfigurationException when identity is not set', () {
      final client = CustomFlagClient(
        config: config(),
        cache: FlagCache(storage: FlagStorage()),
      );

      expect(client.clearCache, throwsA(isA<ConfigurationException>()));
    });

    test('[CustomFlagClient] clearCache empties in-memory cache and removes disk entry', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final storage = FlagStorage();
      final cache = FlagCache(storage: storage);
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true},
        }),
        queryParameters: {'user': 'user_42'},
      );

      client.setIdentity(const Identity(identifier: 'user_42'));
      await client.init();
      expect(client.getFlag('dark_mode').getBool(), true);

      await client.clearCache();

      expect(client.getAllFlags(), isEmpty);
      expect(client.getFlag('dark_mode').value, isNull);
      final disk = await storage.read('user_42');
      expect(disk, isEmpty);
    });

    test('[CustomFlagClient] clearCache emits an empty snapshot on flagStream', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(200, {
          'flags': {'dark_mode': true},
        }),
        queryParameters: {'user': 'user_42'},
      );

      client.setIdentity(const Identity(identifier: 'user_42'));
      await client.init();

      final emissions = <Map<String, Flag>>[];
      client.flagStream.listen(emissions.add);

      await client.clearCache();
      await Future<void>.delayed(Duration.zero);

      expect(emissions, isNotEmpty);
      expect(emissions.last, isEmpty);
    });

    test('[CustomFlagClient] clearCache cancels in-flight refresh — concurrent fetch does not repopulate cache', () async {
      final dio = Dio();
      final adapter = DioAdapter(dio: dio);
      final api = ApiClient(config: config(), dio: dio);
      final cache = FlagCache(storage: FlagStorage());
      final client = CustomFlagClient(
        config: config(),
        apiClient: api,
        cache: cache,
      );

      adapter.onGet(
        '/api/v1/flags',
        (server) => server.reply(
          200,
          {'flags': {'dark_mode': true}},
          delay: const Duration(seconds: 5),
        ),
        queryParameters: {'user': 'user_42'},
      );

      client.setIdentity(const Identity(identifier: 'user_42'));

      final pendingRefresh = client.refresh();
      await Future<void>.delayed(Duration.zero);

      final throwsExpectation = expectLater(
        pendingRefresh,
        throwsA(isA<CustomFlagApiException>()),
      );
      await client.clearCache();
      await throwsExpectation;

      expect(client.getFlag('dark_mode').value, isNull,
          reason: 'cancelled refresh must not repopulate the cache after clearCache');
    });
  });
}
