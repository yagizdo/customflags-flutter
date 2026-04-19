import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'flag_model.dart';

part 'flag_response_model.g.dart';

@JsonSerializable(createToJson: false)
class FlagResponse extends Equatable {
  @JsonKey(fromJson: _flagsFromJson)
  final List<Flag> flags;

  const FlagResponse({required this.flags});

  factory FlagResponse.fromJson(Map<String, dynamic> json) => _$FlagResponseFromJson(json);

  static List<Flag> _flagsFromJson(Map<String, dynamic> json) {
    return json.entries.map((entry) {
      return Flag(key: entry.key, value: entry.value);
    }).toList();
  }

  @override
  List<Object?> get props => [flags];
}
