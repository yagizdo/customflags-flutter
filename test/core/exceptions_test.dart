import 'package:customflags/customflags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomFlagsException', () {
    test('[CustomFlagsException] stores the provided message', () {
      final exception = CustomFlagsException(message: 'Something went wrong');
      expect(exception.message, 'Something went wrong');
    });

    test('[CustomFlagsException] toString includes runtime type and message', () {
      final exception = CustomFlagsException(message: 'test error');
      expect(exception.toString(), contains('CustomFlagsException'));
      expect(exception.toString(), contains('test error'));
    });
  });

  group('ConfigurationException', () {
    test('[ConfigurationException] stores the provided message', () {
      final exception = ConfigurationException(message: 'Missing API key');
      expect(exception.message, 'Missing API key');
    });

    test('[ConfigurationException] toString includes runtime type and message', () {
      final exception = ConfigurationException(message: 'Invalid base URL');
      expect(exception.toString(), contains('ConfigurationException'));
      expect(exception.toString(), contains('Invalid base URL'));
    });

    test('[ConfigurationException] is a CustomFlagsException', () {
      final exception = ConfigurationException(message: 'bad config');
      expect(exception, isA<CustomFlagsException>());
    });
  });

  group('CustomFlagApiException', () {
    test('[CustomFlagApiException] stores statusCode, body and message', () {
      final exception = CustomFlagApiException(
        statusCode: 404,
        body: '{"error": "not found"}',
        message: 'Not found',
      );
      expect(exception.statusCode, 404);
      expect(exception.body, '{"error": "not found"}');
      expect(exception.message, 'Not found');
    });

    test('[CustomFlagApiException] allows null statusCode and body for connection errors', () {
      final exception = CustomFlagApiException(message: 'Connection timeout');
      expect(exception.statusCode, isNull);
      expect(exception.body, isNull);
    });

    test('[CustomFlagApiException] toString includes statusCode and body', () {
      final exception = CustomFlagApiException(
        statusCode: 422,
        body: 'validation failed',
        message: 'Unprocessable',
      );
      final str = exception.toString();
      expect(str, contains('CustomFlagApiException'));
      expect(str, contains('422'));
      expect(str, contains('validation failed'));
    });

    test('[CustomFlagApiException] instances with identical fields are equal', () {
      final a = CustomFlagApiException(statusCode: 400, body: 'x', message: 'err');
      final b = CustomFlagApiException(statusCode: 400, body: 'x', message: 'err');
      final c = CustomFlagApiException(statusCode: 500, body: 'x', message: 'err');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('[CustomFlagApiException] is a CustomFlagsException', () {
      final exception = CustomFlagApiException(message: 'server error');
      expect(exception, isA<CustomFlagsException>());
    });
  });

  group('TypeMismatchException', () {
    test('[TypeMismatchException] builds message from flagKey, expected and actual types', () {
      final exception = TypeMismatchException(
        flagKey: 'dark_mode',
        expectedType: bool,
        actualType: String,
      );
      expect(exception.message, 'Flag "dark_mode" has type String, but expected bool');
    });

    test('[TypeMismatchException] toString includes flagKey and type names', () {
      final exception = TypeMismatchException(
        flagKey: 'theme_color',
        expectedType: String,
        actualType: int,
      );
      expect(exception.toString(), contains('TypeMismatchException'));
      expect(exception.toString(), contains('theme_color'));
      expect(exception.toString(), contains('String'));
      expect(exception.toString(), contains('int'));
    });

    test('[TypeMismatchException] instances with identical fields are equal', () {
      final a = TypeMismatchException(
        flagKey: 'dark_mode',
        expectedType: bool,
        actualType: String,
      );
      final b = TypeMismatchException(
        flagKey: 'dark_mode',
        expectedType: bool,
        actualType: String,
      );
      final c = TypeMismatchException(
        flagKey: 'theme_color',
        expectedType: String,
        actualType: int,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('[TypeMismatchException] reports Null as actualType for null values', () {
      final exception = TypeMismatchException(
        flagKey: 'dark_mode',
        expectedType: bool,
        actualType: Null,
      );
      expect(exception.message, 'Flag "dark_mode" has type Null, but expected bool');
    });

    test('[TypeMismatchException] is a CustomFlagsException', () {
      final exception = TypeMismatchException(
        flagKey: 'k',
        expectedType: bool,
        actualType: String,
      );
      expect(exception, isA<CustomFlagsException>());
    });
  });
}
