import 'package:equatable/equatable.dart';

import 'flag_model.dart';

class FlagResponse extends Equatable {
  final List<Flag> flags;

  const FlagResponse({required this.flags});

  factory FlagResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['flags'] as Map<String, dynamic>;
    return FlagResponse(
      flags: raw.entries.map((e) => Flag(key: e.key, value: e.value)).toList(),
    );
  }

  @override
  List<Object?> get props => [flags];
}
