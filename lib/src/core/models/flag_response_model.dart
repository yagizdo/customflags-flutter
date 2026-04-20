import 'package:equatable/equatable.dart';

import '../exceptions.dart';
import 'flag_model.dart';

class FlagResponse extends Equatable {
  final List<Flag> flags;

  const FlagResponse({required this.flags});

  factory FlagResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['flags'];
    if (raw is! Map<String, dynamic>) {
      throw ApiClientException(
        statusCode: -1,
        body: raw?.toString(),
        message: 'Malformed flag response: expected "flags" to be a Map<String, dynamic>, got ${raw.runtimeType}',
      );
    }
    return FlagResponse(
      flags: raw.entries.map((e) => Flag(key: e.key, value: e.value)).toList(),
    );
  }

  @override
  List<Object?> get props => [flags];
}
