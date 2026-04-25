import 'package:equatable/equatable.dart';

/// Identifies the end user when fetching their feature flags.
///
/// Construct one with whatever value uniquely identifies a user in
/// your system — a user ID, an email, or any opaque string the
/// CustomFlags backend is configured to recognise:
///
/// ```dart
/// final identity = Identity(identifier: 'user_42');
/// // or
/// final identity = Identity(identifier: 'jane@example.com');
/// ```
///
/// The SDK URL-encodes the value before sending it, so pass the raw
/// string — do not pre-encode `@`, spaces, or unicode characters.
class Identity extends Equatable {
  /// The value sent to the backend as the user's identifier.
  ///
  /// Can be a stable user ID (e.g. `'user_42'`), an email
  /// (e.g. `'jane@example.com'`), or any string your CustomFlags
  /// project recognises. Two `Identity` instances with the same
  /// [identifier] are considered equal.
  final String identifier;

  const Identity({required this.identifier});

  @override
  List<Object?> get props => [identifier];
}
