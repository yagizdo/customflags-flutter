import 'package:customflags/customflags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomFlagConfig construction', () {
    test('[CustomFlagConfig] stores apiKey, connectTimeout and receiveTimeout', () {
      final config = CustomFlagConfig(
        apiKey: 'test_key',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 15),
      );

      expect(config.apiKey, 'test_key');
      expect(config.connectTimeout, const Duration(seconds: 5));
      expect(config.receiveTimeout, const Duration(seconds: 15));
    });

    test('[CustomFlagConfig] uses default connectTimeout when none provided', () {
      final config = CustomFlagConfig(apiKey: 'test_key');

      expect(config.connectTimeout, CustomFlagConfig.defaultConnectTimeout);
    });

    test('[CustomFlagConfig] uses default receiveTimeout when none provided', () {
      final config = CustomFlagConfig(apiKey: 'test_key');

      expect(config.receiveTimeout, CustomFlagConfig.defaultReceiveTimeout);
    });

    test('[CustomFlagConfig] defaultConnectTimeout is 10 seconds', () {
      // Pins the documented default so an accidental change flips the test,
      // not just the Duration equality against itself.
      expect(CustomFlagConfig.defaultConnectTimeout, const Duration(seconds: 10));
    });

    test('[CustomFlagConfig] defaultReceiveTimeout is 20 seconds', () {
      expect(CustomFlagConfig.defaultReceiveTimeout, const Duration(seconds: 20));
    });

    test('[CustomFlagConfig] uses provided connectTimeout overriding the default', () {
      final config = CustomFlagConfig(
        apiKey: 'test_key',
        connectTimeout: const Duration(seconds: 3),
      );

      expect(config.connectTimeout, const Duration(seconds: 3));
      expect(config.receiveTimeout, CustomFlagConfig.defaultReceiveTimeout);
    });

    test('[CustomFlagConfig] uses provided receiveTimeout overriding the default', () {
      final config = CustomFlagConfig(
        apiKey: 'test_key',
        receiveTimeout: const Duration(seconds: 45),
      );

      expect(config.receiveTimeout, const Duration(seconds: 45));
      expect(config.connectTimeout, CustomFlagConfig.defaultConnectTimeout);
    });
  });

  group('CustomFlagConfig validation', () {
    test('[CustomFlagConfig] throws ConfigurationException when apiKey is empty', () {
      expect(
        () => CustomFlagConfig(apiKey: ''),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('[CustomFlagConfig] throws ConfigurationException when connectTimeout is zero', () {
      expect(
        () => CustomFlagConfig(
          apiKey: 'test_key',
          connectTimeout: Duration.zero,
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('[CustomFlagConfig] throws ConfigurationException when connectTimeout is negative', () {
      expect(
        () => CustomFlagConfig(
          apiKey: 'test_key',
          connectTimeout: const Duration(seconds: -1),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('[CustomFlagConfig] throws ConfigurationException when receiveTimeout is zero', () {
      expect(
        () => CustomFlagConfig(
          apiKey: 'test_key',
          receiveTimeout: Duration.zero,
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('[CustomFlagConfig] throws ConfigurationException when receiveTimeout is negative', () {
      expect(
        () => CustomFlagConfig(
          apiKey: 'test_key',
          receiveTimeout: const Duration(seconds: -1),
        ),
        throwsA(isA<ConfigurationException>()),
      );
    });

    test('[CustomFlagConfig] empty-apiKey exception message points to the dashboard', () {
      // The message is the only channel a developer sees at construction
      // failure — if this drifts, the dashboard link silently disappears.
      expect(
        () => CustomFlagConfig(apiKey: ''),
        throwsA(
          isA<ConfigurationException>()
              .having((e) => e.message, 'message', contains('customflags.app')),
        ),
      );
    });
  });

  group('CustomFlagConfig equality', () {
    test('[CustomFlagConfig] instances with identical fields are equal', () {
      final a = CustomFlagConfig(
        apiKey: 'key',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      );
      final b = CustomFlagConfig(
        apiKey: 'key',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('[CustomFlagConfig] instances with different apiKey are not equal', () {
      final a = CustomFlagConfig(apiKey: 'key_a');
      final b = CustomFlagConfig(apiKey: 'key_b');

      expect(a, isNot(equals(b)));
    });

    test('[CustomFlagConfig] instances with different connectTimeout are not equal', () {
      final a = CustomFlagConfig(
        apiKey: 'key',
        connectTimeout: const Duration(seconds: 5),
      );
      final b = CustomFlagConfig(
        apiKey: 'key',
        connectTimeout: const Duration(seconds: 6),
      );

      expect(a, isNot(equals(b)));
    });

    test('[CustomFlagConfig] instances with different receiveTimeout are not equal', () {
      final a = CustomFlagConfig(
        apiKey: 'key',
        receiveTimeout: const Duration(seconds: 10),
      );
      final b = CustomFlagConfig(
        apiKey: 'key',
        receiveTimeout: const Duration(seconds: 11),
      );

      expect(a, isNot(equals(b)));
    });
  });
}
