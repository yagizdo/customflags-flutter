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
  // TODO: when added dio we can convert this to Response object
  final String? body;
  ApiClientException({required this.statusCode, this.body, required super.message});

  @override
  String toString() {
    return '$runtimeType(message: $message, statusCode: $statusCode, body: $body)';
  }

  @override
  List<Object?> get props => [message, statusCode, body];
}
