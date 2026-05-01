import 'package:equatable/equatable.dart';

import '../exceptions.dart';
import 'flag_model.dart';

/// The parsed collection of flags returned by the CustomFlags backend.
///
/// Each entry in the backend's response becomes a [Flag] in [flags].
class FlagResponse extends Equatable {
  /// All flags returned by the backend, one per key in the response.
  final List<Flag> flags;

  const FlagResponse({required this.flags});

  /// Parses a [FlagResponse] from the backend's JSON envelope.
  ///
  /// Throws [MalformedResponseException] when the payload is missing
  /// the `flags` field, or `flags` is not a JSON object.
  factory FlagResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['flags'];
    if (raw is! Map<String, dynamic>) {
      throw MalformedResponseException(
        message:
            'Malformed response: expected "flags" to be Map<String, dynamic>, got ${raw.runtimeType}',
      );
    }
    return FlagResponse(
      flags: raw.entries.map((e) => Flag(key: e.key, value: e.value)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'flags': {for (final f in flags) f.key: f.value},
      };

  @override
  List<Object?> get props => [flags];
}
