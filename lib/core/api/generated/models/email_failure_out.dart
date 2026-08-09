// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'email_failure_out.g.dart';

@JsonSerializable()
class EmailFailureOut {
  const EmailFailureOut({
    required this.createdAt,
    required this.emailType,
    required this.entityId,
    required this.entityType,
    required this.eventType,
    required this.id,
    required this.occurredAt,
    required this.reason,
    required this.resendEmailId,
    required this.resolvedAt,
    required this.toEmail,
  });

  factory EmailFailureOut.fromJson(Map<String, Object?> json) =>
      _$EmailFailureOutFromJson(json);

  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'email_type')
  final String emailType;
  @JsonKey(name: 'entity_id')
  final String? entityId;
  @JsonKey(name: 'entity_type')
  final String? entityType;
  @JsonKey(name: 'event_type')
  final String eventType;
  final String id;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;
  final String? reason;
  @JsonKey(name: 'resend_email_id')
  final String resendEmailId;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
  @JsonKey(name: 'to_email')
  final String toEmail;

  Map<String, Object?> toJson() => _$EmailFailureOutToJson(this);
}
