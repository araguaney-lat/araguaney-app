// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'activity_point.g.dart';

@JsonSerializable()
class ActivityPoint {
  const ActivityPoint({
    required this.date,
    required this.draft,
    required this.rejected,
    required this.sealedValue,
    required this.shipped,
    required this.total,
  });

  factory ActivityPoint.fromJson(Map<String, Object?> json) =>
      _$ActivityPointFromJson(json);

  final String date;
  final int draft;
  final int rejected;

  /// The name has been replaced because it contains a keyword. Original name: `sealed`.
  @JsonKey(name: 'sealed')
  final int sealedValue;
  final int shipped;
  final int total;

  Map<String, Object?> toJson() => _$ActivityPointToJson(this);
}
