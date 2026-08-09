// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'box_code_block_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BoxCodeBlockOut _$BoxCodeBlockOutFromJson(Map<String, dynamic> json) =>
    BoxCodeBlockOut(
      available: (json['available'] as num).toInt(),
      codes: (json['codes'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$BoxCodeBlockOutToJson(BoxCodeBlockOut instance) =>
    <String, dynamic>{'available': instance.available, 'codes': instance.codes};
