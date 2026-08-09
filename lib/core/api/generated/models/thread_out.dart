// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'thread_out.g.dart';

@JsonSerializable()
class ThreadOut {
  const ThreadOut({
    required this.body,
    required this.campaignId,
    required this.createdAt,
    required this.id,
    required this.senderId,
    required this.threadType,
    required this.title,
    required this.updatedAt,
  });

  factory ThreadOut.fromJson(Map<String, Object?> json) =>
      _$ThreadOutFromJson(json);

  final String body;
  @JsonKey(name: 'campaign_id')
  final String campaignId;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String id;
  @JsonKey(name: 'sender_id')
  final String? senderId;
  @JsonKey(name: 'thread_type')
  final String threadType;
  final String title;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, Object?> toJson() => _$ThreadOutToJson(this);
}
