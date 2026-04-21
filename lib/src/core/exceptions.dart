import 'package:equatable/equatable.dart';

/// Base class for all exceptions thrown by the CustomFlags SDK.
///
/// Catch [CustomFlagsException] to handle every SDK-originated error in
/// one place, or catch a specific subtype when you need to react
/// differently to network failures, malformed responses, or flag type
/// mismatches.
///
/// ```dart
/// try {
///   final enabled = flag.getBool();
/// } on CustomFlagsException catch (e) {
///   print(e);
/// }
/// ```
sealed class CustomFlagsException with EquatableMixin implements Exception {
  /// Human-readable description of the failure, intended for logs and
  /// developer tooling. When a subclass exposes structured data (like
  /// [ApiClientException.statusCode] or [TypeMismatchException.flagKey]),
  /// read those fields instead of parsing this string.
  final String message;

  CustomFlagsException({required this.message});

  @override
  String toString() {
    return '$runtimeType(message: $message)';
  }

  @override
  List<Object?> get props => [message];
}

/// Thrown when an SDK call is made before the SDK has been initialized.
///
/// Initialize the SDK once at app startup before reading any flags.
final class NotInitializedException extends CustomFlagsException {
  NotInitializedException() : super(message: 'CustomFlags is not initialized, please call CustomFlags.init() first');
}

/// Thrown when the SDK cannot reach the CustomFlags backend.
///
/// Typically caused by no internet connection, DNS resolution failure,
/// or a connection/receive timeout configured on [CustomFlagConfig].
final class NetworkException extends CustomFlagsException {
  NetworkException({super.message = 'Network exception'});
}

/// Thrown when the backend returns a 5xx response indicating a
/// server-side failure. Usually transient — a retry after backoff
/// may succeed, but the caller should not treat the flag value as
/// known until the request completes.
final class ServerException extends CustomFlagsException {
  ServerException({super.message = 'Server exception'});
}

/// Thrown for errors that do not fit any of the other SDK exception
/// categories. Rare in practice — if you encounter one repeatedly,
/// open an issue with the stack trace so the SDK can classify the
/// failure more precisely.
final class UnknownException extends CustomFlagsException {
  UnknownException() : super(message: 'Unknown exception');
}

/// Thrown when [CustomFlagConfig] is constructed with invalid input —
/// for example an empty API key or a non-positive timeout.
final class ConfigurationException extends CustomFlagsException {
  ConfigurationException({required super.message});
}

/// Thrown when the backend returns a non-success HTTP status, typically
/// in the 4xx range.
final class ApiClientException extends CustomFlagsException {
  /// The HTTP status code returned by the backend (e.g. `401`, `404`,
  /// `429`).
  final int statusCode;

  /// The raw response body returned by the backend, or `null` when the
  /// response had no body. Useful for diagnosing why the request was
  /// rejected.
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

/// Thrown when a flag is read as a specific type but its stored value
/// is of a different type — for example calling [Flag.getBool] on a
/// flag whose value is a [String].
final class TypeMismatchException extends CustomFlagsException {
  /// The key of the flag that was read (e.g. `'dark_mode'`).
  final String flagKey;

  /// The Dart type requested at the call site — for example `bool`
  /// when the flag was read via [Flag.getBool].
  final Type expectedType;

  /// The Dart type of the value actually stored for the flag — for
  /// example `String` when the backend returned `'true'` instead of
  /// `true`.
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

/// Thrown when a flag is read but its stored value is `null`.
///
/// Catch this to supply a fallback, or configure the flag on the
/// backend so it always resolves to a non-null value.
final class NullFlagValueException extends CustomFlagsException {
  /// The flag key that was read (e.g. `'dark_mode'`). Use this to
  /// identify which flag needs a backend default or a caller-side
  /// fallback.
  final String flagKey;

  NullFlagValueException({required this.flagKey}) : super(message: 'Flag "$flagKey" has no value (null)');

  @override
  List<Object?> get props => [message, flagKey];
}

/// Thrown when the backend returns a response whose shape does not
/// match what the SDK expects — for example a missing or mistyped
/// `flags` field in the JSON envelope.
final class MalformedResponseException extends CustomFlagsException {
  /// The name of the field in the JSON envelope that was missing or
  /// had the wrong shape (e.g. `'flags'`).
  final String field;

  /// The Dart type the SDK expected at [field] (e.g.
  /// `Map<String, dynamic>`).
  final Type expectedType;

  /// The Dart type the SDK actually received at [field] (e.g.
  /// `List<dynamic>` or `Null` when the field was missing).
  final Type actualType;

  MalformedResponseException({
    required this.field,
    required this.expectedType,
    required this.actualType,
  }) : super(
          message: 'Malformed response: expected "$field" to be $expectedType, got $actualType',
        );

  @override
  List<Object?> get props => [message, field, expectedType, actualType];
}
