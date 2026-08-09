// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'category_stock_out.dart';
import 'center_stock_out.dart';
import 'inn_stock_out.dart';
import 'summary_totals_out.dart';

part 'national_dashboard_out.g.dart';

@JsonSerializable()
class NationalDashboardOut {
  const NationalDashboardOut({
    required this.byCategory,
    required this.byCenter,
    required this.byInn,
    required this.totals,
  });

  factory NationalDashboardOut.fromJson(Map<String, Object?> json) =>
      _$NationalDashboardOutFromJson(json);

  @JsonKey(name: 'by_category')
  final List<CategoryStockOut> byCategory;
  @JsonKey(name: 'by_center')
  final List<CenterStockOut> byCenter;
  @JsonKey(name: 'by_inn')
  final List<InnStockOut> byInn;
  final SummaryTotalsOut totals;

  Map<String, Object?> toJson() => _$NationalDashboardOutToJson(this);
}
