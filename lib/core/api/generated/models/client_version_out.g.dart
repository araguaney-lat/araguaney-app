// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_version_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientVersionOut _$ClientVersionOutFromJson(Map<String, dynamic> json) =>
    ClientVersionOut(
      latest: json['latest'] as String,
      minSupported: json['min_supported'] as String,
    );

Map<String, dynamic> _$ClientVersionOutToJson(ClientVersionOut instance) =>
    <String, dynamic>{
      'latest': instance.latest,
      'min_supported': instance.minSupported,
    };
