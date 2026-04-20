import 'package:customflags/customflags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotInitializedException', () {
    test('[NotInitializedException] uses the default initialization message', () {
      final exception = NotInitializedException();
      expect(exception.message, 'CustomFlags is not initialized, please call CustomFlags.init() first');
    });

    test('[NotInitializedException] toString includes runtime type and message', () {
      final exception = NotInitializedException();
      expect(exception.toString(), contains('NotInitializedException'));
      expect(exception.toString(), contains('not initialized'));
    });
  });

  group('NetworkException', () {
    test('[NetworkException] uses default message when none provided', () {
      final exception = NetworkException();
      expect(exception.message, 'Network exception');
    });

    test('[NetworkException] uses provided message when specified', () {
      final exception = NetworkException(message: 'Timeout');
      expect(exception.message, 'Timeout');
    });

    test('[NetworkException] toString includes runtime type', () {
      final exception = NetworkException();
      expect(exception.toString(), contains('NetworkException'));
    });
  });

  group('ServerException', () {
    test('[ServerException] uses default message when none provided', () {
      final exception = ServerException();
      expect(exception.message, 'Server exception');
    });

    test('[ServerException] uses provided message when specified', () {
      final exception = ServerException(message: 'Service down');
      expect(exception.message, 'Service down');
    });

    test('[ServerException] toString includes runtime type', () {
      final exception = ServerException();
      expect(exception.toString(), contains('ServerException'));
    });
  });

  group('UnknownException', () {
    test('[UnknownException] uses the default unknown error message', () {
      final exception = UnknownException();
      expect(exception.message, 'Unknown exception');
    });

    test('[UnknownException] toString includes runtime type', () {
      final exception = UnknownException();
      expect(exception.toString(), contains('UnknownException'));
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
  });

  group('ApiClientException', () {
    test('[ApiClientException] stores statusCode, body and message', () {
      final exception = ApiClientException(
        statusCode: 404,
        body: '{"error": "not found"}',
        message: 'Not found',
      );
      expect(exception.statusCode, 404);
      expect(exception.body, '{"error": "not found"}');
      expect(exception.message, 'Not found');
    });

    test('[ApiClientException] allows null body', () {
      final exception = ApiClientException(
        statusCode: 400,
        message: 'Bad request',
      );
      expect(exception.body, isNull);
    });

    test('[ApiClientException] toString includes statusCode and body', () {
      final exception = ApiClientException(
        statusCode: 422,
        body: 'validation failed',
        message: 'Unprocessable',
      );
      final str = exception.toString();
      expect(str, contains('ApiClientException'));
      expect(str, contains('422'));
      expect(str, contains('validation failed'));
    });

    test('[ApiClientException] instances with identical fields are equal', () {
      final a = ApiClientException(statusCode: 400, body: 'x', message: 'err');
      final b = ApiClientException(statusCode: 400, body: 'x', message: 'err');
      final c = ApiClientException(statusCode: 500, body: 'x', message: 'err');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
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
  });

  group('NullFlagValueException', () {
    test('[NullFlagValueException] builds message from flagKey', () {
      final exception = NullFlagValueException(flagKey: 'dark_mode');
      expect(exception.message, 'Flag "dark_mode" has no value (null)');
    });

    test('[NullFlagValueException] toString includes runtime type and flagKey', () {
      final exception = NullFlagValueException(flagKey: 'theme_color');
      expect(exception.toString(), contains('NullFlagValueException'));
      expect(exception.toString(), contains('theme_color'));
    });

    test('[NullFlagValueException] instances with identical flagKey are equal', () {
      final a = NullFlagValueException(flagKey: 'dark_mode');
      final b = NullFlagValueException(flagKey: 'dark_mode');
      final c = NullFlagValueException(flagKey: 'theme_color');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('MalformedResponseException', () {
    test('[MalformedResponseException] builds message from field, expected and actual types', () {
      final exception = MalformedResponseException(
        field: 'flags',
        expectedType: Map<String, dynamic>,
        actualType: List<int>,
      );
      expect(
        exception.message,
        'Malformed response: expected "flags" to be Map<String, dynamic>, got List<int>',
      );
    });

    test('[MalformedResponseException] toString includes runtime type and field name', () {
      final exception = MalformedResponseException(
        field: 'flags',
        expectedType: Map<String, dynamic>,
        actualType: String,
      );
      final str = exception.toString();
      expect(str, contains('MalformedResponseException'));
      expect(str, contains('flags'));
      expect(str, contains('Map<String, dynamic>'));
      expect(str, contains('String'));
    });

    test('[MalformedResponseException] instances with identical fields are equal', () {
      final a = MalformedResponseException(
        field: 'flags',
        expectedType: Map<String, dynamic>,
        actualType: List<int>,
      );
      final b = MalformedResponseException(
        field: 'flags',
        expectedType: Map<String, dynamic>,
        actualType: List<int>,
      );
      final c = MalformedResponseException(
        field: 'flags',
        expectedType: Map<String, dynamic>,
        actualType: String,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
