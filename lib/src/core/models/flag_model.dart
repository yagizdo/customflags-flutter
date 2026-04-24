import 'package:equatable/equatable.dart';

import '../exceptions.dart';

/// A single feature flag resolved from the CustomFlags backend.
///
/// Read the flag's value through the typed getter that matches its
/// stored type — [getBool], [getString], [getInt], [getDouble], or
/// [getJson]. Each getter throws [TypeMismatchException] when the
/// stored value is of a different type or `null`.
class Flag extends Equatable {
  /// Identifier used to look up the flag — matches the key configured
  /// on the CustomFlags dashboard (e.g. `'dark_mode'`, `'checkout_v2'`).
  final String key;

  /// The raw value stored for this flag, as received from the backend.
  ///
  /// Prefer the typed getters over reading this directly — they handle
  /// null checks and type validation for you.
  final Object? value;

  const Flag({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];

  /// Returns the flag's value as a [bool].
  ///
  /// Throws [TypeMismatchException] if the value is `null` or not a [bool].
  bool getBool() {
    final v = value;
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: bool, actualType: Null);
    }
    if (v is bool) {
      return v;
    }
    throw TypeMismatchException(flagKey: key, expectedType: bool, actualType: v.runtimeType);
  }

  /// Returns the flag's value as a [String].
  ///
  /// Throws [TypeMismatchException] if the value is `null` or not a [String].
  String getString() {
    final v = value;
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: String, actualType: Null);
    }
    if (v is String) {
      return v;
    }
    throw TypeMismatchException(flagKey: key, expectedType: String, actualType: v.runtimeType);
  }

  /// Returns the flag's value as an [int].
  ///
  /// Throws [TypeMismatchException] if the value is `null` or not an [int].
  int getInt() {
    final v = value;
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: int, actualType: Null);
    }
    if (v is int) {
      return v;
    }
    throw TypeMismatchException(flagKey: key, expectedType: int, actualType: v.runtimeType);
  }

  /// Returns the flag's value as a [double].
  ///
  /// Accepts any finite number — values stored as `int` or `double`
  /// are both returned as [double]. Throws [TypeMismatchException]
  /// if the value is `null` or not a finite number.
  double getDouble() {
    final v = value;
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: double, actualType: Null);
    }
    if (v is num && v.isFinite) {
      return v.toDouble();
    }
    throw TypeMismatchException(flagKey: key, expectedType: double, actualType: v.runtimeType);
  }

  /// Returns the flag's value as a JSON object (`Map<String, dynamic>`).
  ///
  /// Throws [TypeMismatchException] if the value is `null` or not a JSON object.
  Map<String, dynamic> getJson() {
    final v = value;
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: Map<String, dynamic>, actualType: Null);
    }
    if (v is Map<String, dynamic>) {
      return v;
    }
    throw TypeMismatchException(flagKey: key, expectedType: Map<String, dynamic>, actualType: v.runtimeType);
  }
}
