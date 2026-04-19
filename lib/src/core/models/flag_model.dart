import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../exceptions.dart';

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

  bool getBool() {
    final v = value;
    if (v is bool) {
      return v;
    }
    throw TypeMismatchException(flagKey: key, expectedType: bool, actualType: v.runtimeType);
  }

  String getString() {
    final v = value;
    if (v is String) {
      return v;
    }
    throw TypeMismatchException(flagKey: key, expectedType: String, actualType: v.runtimeType);
  }

  int getInt() {
    final v = value;
    if (v is int) {
      return v;
    }
    throw TypeMismatchException(flagKey: key, expectedType: int, actualType: v.runtimeType);
  }

  double getDouble() {
    final v = value;
    if (v is num) {
      return v.toDouble();
    }
    throw TypeMismatchException(flagKey: key, expectedType: double, actualType: v.runtimeType);
  }

  Map<String, dynamic> getJson() {
    final v = value;
    if (v is Map<String, dynamic>) {
      return v;
    }
    throw TypeMismatchException(flagKey: key, expectedType: Map<String, dynamic>, actualType: v.runtimeType);
  }
}
