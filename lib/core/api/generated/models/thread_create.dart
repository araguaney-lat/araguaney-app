// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'thread_create.g.dart';

@JsonSerializable()
class ThreadCreate {
  const ThreadCreate({
    required this.body,
    required this.campaignId,
    required this.threadType,
    required this.title,
    this.recipientIds = const [],
  });

  factory ThreadCreate.fromJson(Map<String, Object?> json) =>
      _$ThreadCreateFromJson(json);

  final String body;
  @JsonKey(name: 'campaign_id')
  final String campaignId;
  @JsonKey(name: 'recipient_ids')
  final List<String> recipientIds;
  @JsonKey(name: 'thread_type')
  final String threadType;
  final String title;

  Map<String, Object?> toJson() => _$ThreadCreateToJson(this);
}
