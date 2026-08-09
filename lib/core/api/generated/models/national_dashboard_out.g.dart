// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'national_dashboard_out.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NationalDashboardOut _$NationalDashboardOutFromJson(
  Map<String, dynamic> json,
) => NationalDashboardOut(
  byCategory: (json['by_category'] as List<dynamic>)
      .map((e) => CategoryStockOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  byCenter: (json['by_center'] as List<dynamic>)
      .map((e) => CenterStockOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  byInn: (json['by_inn'] as List<dynamic>)
      .map((e) => InnStockOut.fromJson(e as Map<String, dynamic>))
      .toList(),
  totals: SummaryTotalsOut.fromJson(json['totals'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NationalDashboardOutToJson(
  NationalDashboardOut instance,
) => <String, dynamic>{
  'by_category': instance.byCategory,
  'by_center': instance.byCenter,
  'by_inn': instance.byInn,
  'totals': instance.totals,
};
