import 'package:araguaney_app/core/db/app_database.dart';

/// Momento fijo para que las pruebas no dependan del reloj de quien las corre.
final testNow = DateTime.utc(2026, 8, 10, 12);

ProductTypeRow productTypeRow({
  String id = 'pt-1',
  String displayName = 'Paracetamol 500 mg',
  String category = 'medicamento',
  String? campaignId,
  bool isControlled = false,
}) => ProductTypeRow(
  id: id,
  displayName: displayName,
  category: category,
  isControlled: isControlled,
  campaignId: campaignId,
  createdAt: testNow,
);

BoxRow boxRow({
  String id = 'box-1',
  String code = 'CJ-0001',
  String centerId = 'center-1',
  String productTypeId = 'pt-1',
  int quantity = 10,
  String unit = 'unidad',
  String status = 'open',
  DateTime? createdAt,
}) => BoxRow(
  id: id,
  code: code,
  centerId: centerId,
  productTypeId: productTypeId,
  quantity: quantity,
  unit: unit,
  status: status,
  createdAt: createdAt ?? testNow,
);

Map<String, Object?> productTypeJson({
  String id = 'pt-1',
  String displayName = 'Paracetamol 500 mg',
  String category = 'medicamento',
  String? campaignId,
}) => {
  'id': id,
  'display_name': displayName,
  'category': category,
  'brand': null,
  'campaign_id': campaignId,
  'created_at': testNow.toIso8601String(),
  'default_unit': 'unidad',
  'form': null,
  'gtin': null,
  'inn_name': null,
  'is_controlled': false,
  'min_shelf_life_days': null,
  'strength': null,
  'unit_weight_kg': null,
  'unspsc_code': null,
};

Map<String, Object?> boxJson({
  String id = 'box-1',
  String code = 'CJ-0001',
  String productTypeId = 'pt-1',
  String status = 'open',
  int quantity = 10,
}) => {
  'id': id,
  'code': code,
  'center_id': 'center-1',
  'product_type_id': productTypeId,
  'quantity': quantity,
  'unit': 'unidad',
  'status': status,
  'batch': null,
  'created_at': testNow.toIso8601String(),
  'expiry_date': null,
  'intake_id': null,
  'pallet_id': null,
  'reject_reason': null,
  'sealed_at': null,
  'weight_kg': null,
};
