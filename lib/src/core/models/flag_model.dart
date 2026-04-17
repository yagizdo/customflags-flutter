import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flag_model.g.dart';

@JsonSerializable()
class Flag extends Equatable {
  final String key;
  final dynamic value;

  const Flag({required this.key, required this.value});

  factory Flag.fromJson(Map<String, dynamic> json) => _$FlagFromJson(json);

  Map<String, dynamic> toJson() => _$FlagToJson(this);

  @override
  List<Object?> get props => [key, value];
}
