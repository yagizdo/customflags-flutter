import 'package:customflags/customflags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    test('[CustomFlagApiException] toString includes statusCode and message but not body', () {
      final exception = CustomFlagApiException(
        statusCode: 422,
        body: 'validation failed',
        message: 'Unprocessable',
      );
      final str = exception.toString();
      expect(str, contains('CustomFlagApiException'));
      expect(str, contains('422'));
      expect(str, contains('Unprocessable'));
      expect(str, isNot(contains('validation failed')));
    });

    test('[CustomFlagApiException] body sanitization replaces control characters with spaces', () {
      final exception = CustomFlagApiException(
        statusCode: 500,
        body: 'line1\nline2\rline3\x00null',
        message: 'err',
      );
      expect(exception.body, 'line1 line2 line3 null');
    });

    test('[CustomFlagApiException] body is preserved as-is when within the size limit', () {
      final exception = CustomFlagApiException(
        statusCode: 400,
        body: 'short body',
        message: 'err',
      );
      expect(exception.body, 'short body');
    });

    test('[CustomFlagApiException] body is truncated when longer than 512 characters', () {
      final long = 'a' * 600;
      final exception = CustomFlagApiException(
        statusCode: 500,
        body: long,
        message: 'err',
      );
      expect(exception.body, startsWith('a' * 512));
      expect(exception.body, contains('truncated 88 chars'));
    });

    test('[CustomFlagApiException] body remains null when none provided', () {
      final exception = CustomFlagApiException(message: 'connection timeout');
      expect(exception.body, isNull);
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

  group('MalformedResponseException', () {
    test('[MalformedResponseException] stores the provided message', () {
      final exception = MalformedResponseException(message: 'flags missing');
      expect(exception.message, 'flags missing');
    });

    test('[MalformedResponseException] is a CustomFlagsException', () {
      final exception = MalformedResponseException(message: 'x');
      expect(exception, isA<CustomFlagsException>());
    });

    test('[MalformedResponseException] toString includes runtime type and message', () {
      final exception = MalformedResponseException(message: 'bad envelope');
      expect(exception.toString(), contains('MalformedResponseException'));
      expect(exception.toString(), contains('bad envelope'));
    });
  });

  group('InvalidFlagValueException', () {
    test('[InvalidFlagValueException] stores the provided message', () {
      final exception = InvalidFlagValueException(message: 'value is NaN');
      expect(exception.message, 'value is NaN');
    });

    test('[InvalidFlagValueException] is a CustomFlagsException', () {
      final exception = InvalidFlagValueException(message: 'x');
      expect(exception, isA<CustomFlagsException>());
    });

    test('[InvalidFlagValueException] toString includes runtime type and message', () {
      final exception = InvalidFlagValueException(message: 'value out of range');
      expect(exception.toString(), contains('InvalidFlagValueException'));
      expect(exception.toString(), contains('value out of range'));
    });
  });
}
