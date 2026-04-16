import 'package:customflags/customflags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotInitializedException', () {
    test('has correct default message', () {
      final exception = NotInitializedException();
      expect(exception.message, 'CustomFlags is not initialized, please call CustomFlags.init() first');
    });

    test('toString contains class name and message', () {
      final exception = NotInitializedException();
      expect(exception.toString(), contains('NotInitializedException'));
      expect(exception.toString(), contains('not initialized'));
    });
  });

  group('NetworkException', () {
    test('has correct default message', () {
      final exception = NetworkException();
      expect(exception.message, 'Network exception');
    });

    test('accepts custom message', () {
      final exception = NetworkException(message: 'Timeout');
      expect(exception.message, 'Timeout');
    });

    test('toString contains class name', () {
      final exception = NetworkException();
      expect(exception.toString(), contains('NetworkException'));
    });
  });

  group('ServerException', () {
    test('has correct default message', () {
      final exception = ServerException();
      expect(exception.message, 'Server exception');
    });

    test('accepts custom message', () {
      final exception = ServerException(message: 'Service down');
      expect(exception.message, 'Service down');
    });

    test('toString contains class name', () {
      final exception = ServerException();
      expect(exception.toString(), contains('ServerException'));
    });
  });

  group('UnknownException', () {
    test('has correct default message', () {
      final exception = UnknownException();
      expect(exception.message, 'Unknown exception');
    });

    test('toString contains class name', () {
      final exception = UnknownException();
      expect(exception.toString(), contains('UnknownException'));
    });
  });

  group('ApiConfigurationException', () {
    test('requires message', () {
      final exception = ApiConfigurationException(message: 'Missing API key');
      expect(exception.message, 'Missing API key');
    });

    test('toString contains class name and message', () {
      final exception = ApiConfigurationException(message: 'Invalid base URL');
      expect(exception.toString(), contains('ApiConfigurationException'));
      expect(exception.toString(), contains('Invalid base URL'));
    });
  });

  group('ApiClientException', () {
    test('carries statusCode and body', () {
      final exception = ApiClientException(
        statusCode: 404,
        body: '{"error": "not found"}',
        message: 'Not found',
      );
      expect(exception.statusCode, 404);
      expect(exception.body, '{"error": "not found"}');
      expect(exception.message, 'Not found');
    });

    test('body can be null', () {
      final exception = ApiClientException(
        statusCode: 400,
        message: 'Bad request',
      );
      expect(exception.body, isNull);
    });

    test('toString contains statusCode and body', () {
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

    test('equality compares all fields', () {
      final a = ApiClientException(statusCode: 400, body: 'x', message: 'err');
      final b = ApiClientException(statusCode: 400, body: 'x', message: 'err');
      final c = ApiClientException(statusCode: 500, body: 'x', message: 'err');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
