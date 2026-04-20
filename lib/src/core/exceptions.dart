import 'package:equatable/equatable.dart';

sealed class CustomFlagsException with EquatableMixin implements Exception {
  final String message;

  CustomFlagsException({required this.message});

  @override
  String toString() {
    return '$runtimeType(message: $message)';
  }

  @override
  List<Object?> get props => [message];
}

final class NotInitializedException extends CustomFlagsException {
  NotInitializedException() : super(message: 'CustomFlags is not initialized, please call CustomFlags.init() first');
}

final class NetworkException extends CustomFlagsException {
  NetworkException({super.message = 'Network exception'});
}

final class ServerException extends CustomFlagsException {
  ServerException({super.message = 'Server exception'});
}

final class UnknownException extends CustomFlagsException {
  UnknownException() : super(message: 'Unknown exception');
}

final class ConfigurationException extends CustomFlagsException {
  ConfigurationException({required super.message});
}

final class ApiClientException extends CustomFlagsException {
  final int statusCode;
  // TODO(dio): replace raw `body` with dio's Response once the Dio client is integrated.
  final String? body;
  ApiClientException({required this.statusCode, this.body, required super.message});

  @override
  String toString() {
    return '$runtimeType(message: $message, statusCode: $statusCode, body: $body)';
  }

  @override
  List<Object?> get props => [message, statusCode, body];
}

final class TypeMismatchException extends CustomFlagsException {
  final String flagKey;
  final Type expectedType;
  final Type actualType;

  TypeMismatchException({
    required this.flagKey,
    required this.expectedType,
    required this.actualType,
  }) : super(
         message: 'Flag "$flagKey" has type $actualType, but expected $expectedType',
       );

  @override
  List<Object?> get props => [message, flagKey, expectedType, actualType];
}

final class NullFlagValueException extends CustomFlagsException {
  final String flagKey;

  NullFlagValueException({required this.flagKey})
    : super(message: 'Flag "$flagKey" has no value (null)');

  @override
  List<Object?> get props => [message, flagKey];
}

final class MalformedResponseException extends CustomFlagsException {
  final String field;
  final Type expectedType;
  final Type actualType;

  MalformedResponseException({
    required this.field,
    required this.expectedType,
    required this.actualType,
  }) : super(
         message:
             'Malformed response: expected "$field" to be $expectedType, got $actualType',
       );

  @override
  List<Object?> get props => [message, field, expectedType, actualType];
}
