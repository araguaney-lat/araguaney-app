// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intake_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IntakeOut _$IntakeOutFromJson(Map<String, dynamic> json) => IntakeOut(
  campaignId: json['campaign_id'] as String,
  centerId: json['center_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  donanteLibre: json['donante_libre'] as String?,
  id: json['id'] as String,
  notes: json['notes'] as String?,
  donor: json['donor'] == null
      ? null
      : DonorOut.fromJson(json['donor'] as Map<String, dynamic>),
  boxes:
      (json['boxes'] as List<dynamic>?)
          ?.map(
            (e) => AppSchemasIntakeBoxOut.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const [],
);

Map<String, dynamic> _$IntakeOutToJson(IntakeOut instance) => <String, dynamic>{
  'boxes': instance.boxes,
  'campaign_id': instance.campaignId,
  'center_id': instance.centerId,
  'created_at': instance.createdAt.toIso8601String(),
  'donante_libre': instance.donanteLibre,
  'donor': instance.donor,
  'id': instance.id,
  'notes': instance.notes,
};
