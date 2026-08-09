// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_failure_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailFailureOut _$EmailFailureOutFromJson(Map<String, dynamic> json) =>
    EmailFailureOut(
      createdAt: DateTime.parse(json['created_at'] as String),
      emailType: json['email_type'] as String,
      entityId: json['entity_id'] as String?,
      entityType: json['entity_type'] as String?,
      eventType: json['event_type'] as String,
      id: json['id'] as String,
      occurredAt: json['occurred_at'] == null
          ? null
          : DateTime.parse(json['occurred_at'] as String),
      reason: json['reason'] as String?,
      resendEmailId: json['resend_email_id'] as String,
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      toEmail: json['to_email'] as String,
    );

Map<String, dynamic> _$EmailFailureOutToJson(EmailFailureOut instance) =>
    <String, dynamic>{
      'created_at': instance.createdAt.toIso8601String(),
      'email_type': instance.emailType,
      'entity_id': instance.entityId,
      'entity_type': instance.entityType,
      'event_type': instance.eventType,
      'id': instance.id,
      'occurred_at': instance.occurredAt?.toIso8601String(),
      'reason': instance.reason,
      'resend_email_id': instance.resendEmailId,
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'to_email': instance.toEmail,
    };
