// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'request_create.g.dart';

@JsonSerializable()
class RequestCreate {
  const RequestCreate({required this.description, required this.title});

  factory RequestCreate.fromJson(Map<String, Object?> json) =>
      _$RequestCreateFromJson(json);

  final String description;
  final String title;

  Map<String, Object?> toJson() => _$RequestCreateToJson(this);
}
