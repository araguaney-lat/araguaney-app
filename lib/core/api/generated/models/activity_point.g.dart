// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_point.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityPoint _$ActivityPointFromJson(Map<String, dynamic> json) =>
    ActivityPoint(
      date: json['date'] as String,
      draft: (json['draft'] as num).toInt(),
      rejected: (json['rejected'] as num).toInt(),
      sealedValue: (json['sealed'] as num).toInt(),
      shipped: (json['shipped'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$ActivityPointToJson(ActivityPoint instance) =>
    <String, dynamic>{
      'date': instance.date,
      'draft': instance.draft,
      'rejected': instance.rejected,
      'sealed': instance.sealedValue,
      'shipped': instance.shipped,
      'total': instance.total,
    };
