// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_create.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestCreate _$RequestCreateFromJson(Map<String, dynamic> json) =>
    RequestCreate(
      description: json['description'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$RequestCreateToJson(RequestCreate instance) =>
    <String, dynamic>{
      'description': instance.description,
      'title': instance.title,
    };
