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
  /// When [fallback] is provided (non-null), it is returned in place of the
  /// throw whenever the stored value is `null` or not a [bool]. When
  /// [fallback] is omitted or explicitly `null`, the strict behavior is
  /// preserved and a [TypeMismatchException] is thrown.
  bool getBool({bool? fallback}) {
    final v = value;
    if (v is bool) {
      return v;
    }
    if (fallback != null) {
      return fallback;
    }
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: bool, actualType: Null);
    }
    throw TypeMismatchException(flagKey: key, expectedType: bool, actualType: v.runtimeType);
  }

  /// Returns the flag's value as a [String].
  ///
  /// When [fallback] is provided (non-null), it is returned in place of the
  /// throw whenever the stored value is `null` or not a [String]. When
  /// [fallback] is omitted or explicitly `null`, the strict behavior is
  /// preserved and a [TypeMismatchException] is thrown.
  String getString({String? fallback}) {
    final v = value;
    if (v is String) {
      return v;
    }
    if (fallback != null) {
      return fallback;
    }
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: String, actualType: Null);
    }
    throw TypeMismatchException(flagKey: key, expectedType: String, actualType: v.runtimeType);
  }

  /// Returns the flag's value as an [int].
  ///
  /// When [fallback] is provided (non-null), it is returned in place of the
  /// throw whenever the stored value is `null` or not an [int]. Note that a
  /// [double] value never satisfies the strict path here — there is no
  /// silent truncation — so a `double` value with a fallback returns the
  /// fallback rather than coercing.
  int getInt({int? fallback}) {
    final v = value;
    if (v is int) {
      return v;
    }
    if (fallback != null) {
      return fallback;
    }
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: int, actualType: Null);
    }
    throw TypeMismatchException(flagKey: key, expectedType: int, actualType: v.runtimeType);
  }

  /// Returns the flag's value as a [double].
  ///
  /// Accepts any finite number — values stored as `int` or `double` are both
  /// returned as [double]. When [fallback] is provided (non-null), it is
  /// returned in place of the throw whenever the stored value is `null`,
  /// non-numeric, or non-finite (`NaN`, `±Infinity`). When [fallback] is
  /// omitted or explicitly `null`, the strict behavior is preserved:
  /// [TypeMismatchException] for null/non-num values, [InvalidFlagValueException]
  /// for non-finite numbers.
  double getDouble({double? fallback}) {
    final v = value;
    if (v is num && v.isFinite) {
      return v.toDouble();
    }
    if (fallback != null) {
      return fallback;
    }
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: double, actualType: Null);
    }
    if (v is! num) {
      throw TypeMismatchException(flagKey: key, expectedType: double, actualType: v.runtimeType);
    }
    throw InvalidFlagValueException(
      message: 'Flag "$key" has value $v, which is not a finite number',
    );
  }

  /// Returns the flag's value as a JSON object (`Map<String, dynamic>`).
  ///
  /// When [fallback] is provided (non-null), it is returned in place of the
  /// throw whenever the stored value is `null` or not a `Map<String, dynamic>`.
  /// When [fallback] is omitted or explicitly `null`, the strict behavior is
  /// preserved and a [TypeMismatchException] is thrown.
  Map<String, dynamic> getJson({Map<String, dynamic>? fallback}) {
    final v = value;
    if (v is Map<String, dynamic>) {
      return v;
    }
    if (fallback != null) {
      return fallback;
    }
    if (v == null) {
      throw TypeMismatchException(flagKey: key, expectedType: Map<String, dynamic>, actualType: Null);
    }
    throw TypeMismatchException(flagKey: key, expectedType: Map<String, dynamic>, actualType: v.runtimeType);
  }
}
