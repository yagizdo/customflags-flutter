import 'package:equatable/equatable.dart';

import '../constants/regex_patterns.dart';

/// Base class for all exceptions thrown by the CustomFlags SDK.
///
/// Catch [CustomFlagsException] to handle every SDK-originated error in
/// one place, or catch a specific subtype ([CustomFlagApiException],
/// [ConfigurationException], [TypeMismatchException]) when you need to
/// react differently.
///
/// ```dart
/// try {
///   final flags = await client.fetchAllFlags();
/// } on CustomFlagApiException catch (e) {
///   log('HTTP ${e.statusCode}: ${e.body}');
/// } on MalformedResponseException catch (e) {
///   log('Bad response shape: ${e.message}');
/// } on CustomFlagsException catch (e) {
///   log('SDK error: $e');
/// }
/// ```
abstract class CustomFlagsException with EquatableMixin implements Exception {
  final String message;

  CustomFlagsException({required this.message});

  @override
  String toString() => '$runtimeType(message: $message)';

  @override
  List<Object?> get props => [message];
}

/// Thrown when [CustomFlagConfig] is constructed with invalid input —
/// for example an empty API key or a non-positive timeout — or when the
/// SDK is used before initialization.
final class ConfigurationException extends CustomFlagsException {
  ConfigurationException({required super.message});
}

/// Thrown when an HTTP request to the CustomFlags backend fails.
///
/// Covers network errors (no connection, timeout), server errors (5xx),
/// and client errors (4xx). Check [statusCode] to distinguish — it is
/// `null` for connection-level failures where no HTTP response was
/// received.
final class CustomFlagApiException extends CustomFlagsException {
  /// The HTTP status code returned by the backend (e.g. `401`, `500`),
  /// or `null` when the failure occurred before a response was received
  /// (connection timeout, DNS failure, no internet).
  final int? statusCode;

  /// The response body returned by the backend, with control characters
  /// (CR, LF, NUL, etc.) replaced by spaces to prevent log injection,
  /// and truncated to [_maxBodyChars] characters when longer.
  ///
  /// Not included in [toString] by default — access this field
  /// explicitly when you want to display or log the response detail.
  final String? body;

  static const int _maxBodyChars = 512;

  CustomFlagApiException({this.statusCode, String? body, required super.message})
      : body = _sanitizeAndTruncate(body);

  static String? _sanitizeAndTruncate(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(kLogInjectionControlCharsPattern, ' ');
    return cleaned.length <= _maxBodyChars
        ? cleaned
        : '${cleaned.substring(0, _maxBodyChars)}... [truncated ${cleaned.length - _maxBodyChars} chars]';
  }

  @override
  String toString() => '$runtimeType(message: $message, statusCode: $statusCode)';

  @override
  List<Object?> get props => [message, statusCode, body];
}

/// Thrown when a flag is read as a specific type but its stored value
/// is of a different type — for example calling [Flag.getBool] on a
/// flag whose value is a [String], or reading a flag whose value is
/// `null` (reported as `actualType: Null`).
final class TypeMismatchException extends CustomFlagsException {
  /// The key of the flag that was read (e.g. `'dark_mode'`).
  final String flagKey;

  /// The Dart type requested at the call site — for example `bool`
  /// when the flag was read via [Flag.getBool].
  final Type expectedType;

  /// The Dart type of the value actually stored for the flag — `Null`
  /// when the value is `null`, or e.g. `String` when the backend
  /// returned `'true'` instead of `true`.
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

/// Thrown when the backend response does not match the expected
/// envelope shape — for example a missing `flags` key, or `flags`
/// being a non-Map value.
final class MalformedResponseException extends CustomFlagsException {
  MalformedResponseException({required super.message});
}

/// Thrown when a flag's stored value is well-typed but not valid for
/// the requested type — for example a non-finite double (`NaN`,
/// `Infinity`) returned from [Flag.getDouble].
final class InvalidFlagValueException extends CustomFlagsException {
  InvalidFlagValueException({required super.message});
}
