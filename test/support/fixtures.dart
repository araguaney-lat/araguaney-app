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
  DateTime? sealedAt,
}) => BoxRow(
  id: id,
  code: code,
  centerId: centerId,
  productTypeId: productTypeId,
  quantity: quantity,
  unit: unit,
  status: status,
  sealedAt: sealedAt,
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

Map<String, Object?> intakeJson({
  String id = 'intake-1',
  String campaignId = 'campaign-1',
  List<Map<String, Object?>>? boxes,
}) => {
  'id': id,
  'center_id': 'center-1',
  'campaign_id': campaignId,
  'donante_libre': null,
  'donor': null,
  'notes': null,
  'created_at': testNow.toIso8601String(),
  'boxes': boxes ?? [intakeBoxJson()],
};

/// La caja tal como la devuelve una captura: sin `center_id` ni `pallet_id`,
/// que a esa altura todavía no existen.
Map<String, Object?> intakeBoxJson({
  String id = 'box-1',
  String code = 'BX-0001',
  String status = 'open',
}) => {
  'id': id,
  'code': code,
  'product_type_id': 'pt-1',
  'quantity': 10,
  'unit': 'unidad',
  'status': status,
  'batch': null,
  'created_at': testNow.toIso8601String(),
  'expiry_date': null,
  'reject_reason': null,
  'weight_kg': null,
};

Map<String, Object?> publicBoxJson({
  String code = 'BX-0001',
  String status = 'sealed',
  String displayName = 'Paracetamol 500 mg',
}) => {
  'code': code,
  'status': status,
  'category': 'medicamento',
  'display_name': displayName,
  'quantity': 10,
  'unit': 'unidad',
  'expiry_date': null,
  'sealed_at': testNow.toIso8601String(),
  'delivered': false,
  'delivered_at': null,
};

Map<String, Object?> publicPalletJson({
  String code = 'TM-0001',
  String status = 'open',
  String centerName = 'Centro Caracas',
}) => {
  'code': code,
  'status': status,
  'center_name': centerName,
  'box_count': 4,
  'closed_at': null,
  'delivered': false,
  'delivered_at': null,
};

Map<String, Object?> donationJson({
  String code = 'DN-0001',
  String status = 'REGISTERED',
  List<Map<String, Object?>>? items,
}) => {
  'id': 'donation-1',
  'code': code,
  'status': status,
  'created_at': testNow.toIso8601String(),
  'registered_at': testNow.toIso8601String(),
  'atypical_volume': false,
  'intended_campaign_id': null,
  'intended_center_id': null,
  'received_center_id': null,
  'notes': null,
  'photos': const [],
  'items':
      items ??
      [
        {
          'id': 'item-1',
          'quantity': 3,
          'unit': 'caja',
          'added_by': 'donor',
          'free_text': 'Paracetamol 500 mg',
          'product_type_id': null,
          'reception_status': null,
        },
      ],
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

Map<String, Object?> riskReviewJson({
  String id = 'rr-1',
  String? intakeId = 'intake-1',
  String kind = 'ATYPICAL_VOLUME',
  String? reason,
  String status = 'open',
}) => {
  'id': id,
  'center_id': 'center-1',
  'intake_id': intakeId,
  'kind': kind,
  'reason': reason,
  'status': status,
  'boxes': null,
  'review_note': null,
  'reviewed_at': null,
  'created_at': testNow.toIso8601String(),
};

Map<String, Object?> shipmentJson({
  String id = 'shipment-1',
  String reference = 'ENV-01',
  String destination = 'Caracas',
  String status = 'delivered',
}) => {
  'id': id,
  'reference': reference,
  'destination': destination,
  'status': status,
  'center_id': 'center-1',
  'campaign_id': null,
  'carrier': null,
  'closed_at': null,
  'created_at': testNow.toIso8601String(),
  'delivered_at': testNow.toIso8601String(),
  'height_profile': null,
  'height_warnings': const [],
  'notes': null,
  'pallets': const [],
  'reconciled_at': null,
  'shipped_at': null,
};

Map<String, Object?> palletJson({
  String id = 'pallet-1',
  String code = 'TM-0001',
  String status = 'open',
  DateTime? closedAt,
}) => {
  'id': id,
  'code': code,
  'center_id': 'center-1',
  'shipment_id': null,
  'status': status,
  'notes': null,
  'tare_weight_kg': null,
  'gross_weight_kg': null,
  'height_cm': null,
  'closed_at': closedAt?.toIso8601String(),
  'created_at': testNow.toIso8601String(),
};

Map<String, Object?> palletDetailJson({
  String id = 'pallet-1',
  String code = 'TM-0001',
  String status = 'open',
  List<Map<String, Object?>>? boxes,
}) => {
  ...palletJson(id: id, code: code, status: status),
  'boxes': boxes ?? [boxJson()],
  'boxes_weight_kg': null,
  'weight_discrepancy_kg': null,
};

Map<String, Object?> incidentJson({
  String id = 'incident-1',
  String type = 'DAMAGE',
  String description = 'Tarima mojada',
  String status = 'open',
  DateTime? resolvedAt,
}) => {
  'id': id,
  'shipment_id': 'shipment-1',
  'pallet_id': null,
  'box_id': null,
  'type': type,
  'description': description,
  'status': status,
  'resolution_note': null,
  'resolved_at': resolvedAt?.toIso8601String(),
  'created_at': testNow.toIso8601String(),
};

Map<String, Object?> receptionJson({
  int received = 10,
  int totalBoxes = 10,
  String? consigneeName = 'Ana Pérez',
}) => {
  'id': 'reception-1',
  'shipment_id': 'shipment-1',
  'received_at': testNow.toIso8601String(),
  'consignee_name': consigneeName,
  'notes': null,
  'lines': const [],
  'pallet_weights': const [],
  'shrinkage': {
    'total_boxes': totalBoxes,
    'received': received,
    'not_received': totalBoxes - received,
    'shrinkage_pct': totalBoxes == 0
        ? 0
        : ((totalBoxes - received) / totalBoxes * 100).round(),
  },
};

Map<String, Object?> transferJson({
  String id = 'transfer-1',
  String status = 'REQUESTED',
  String fromCenterId = 'origin',
  String toCenterId = 'dest',
  List<Map<String, Object?>>? boxes,
  List<Map<String, Object?>>? events,
}) => {
  'id': id,
  'from_center_id': fromCenterId,
  'to_center_id': toCenterId,
  'status': status,
  'initiated_by': 'user-1',
  'notes': null,
  'created_at': testNow.toIso8601String(),
  'updated_at': testNow.toIso8601String(),
  'boxes': boxes ?? [boxJson()],
  'events': events ?? const [],
};

Map<String, Object?> threadJson({
  String id = 'thread-1',
  String title = 'Faltan cajas',
  String body = 'Nos quedamos sin cajas medianas',
  String threadType = 'PUBLIC',
}) => {
  'id': id,
  'title': title,
  'body': body,
  'sender_id': 'user-1',
  'campaign_id': 'campaign-1',
  'thread_type': threadType,
  'created_at': testNow.toIso8601String(),
  'updated_at': testNow.toIso8601String(),
};

Map<String, Object?> replyJson({
  String id = 'reply-1',
  String body = 'Salgo con veinte',
}) => {
  'id': id,
  'thread_id': 'thread-1',
  'sender_id': 'user-2',
  'body': body,
  'created_at': testNow.toIso8601String(),
  'attachments': const [],
};

Map<String, Object?> threadDetailJson({
  String body = 'Nos quedamos sin cajas medianas',
  List<Map<String, Object?>>? replies,
  List<Map<String, Object?>>? attachments,
}) => {
  ...threadJson(body: body),
  'replies': replies ?? const [],
  'attachments': attachments ?? const [],
  'participant_ids': const [],
};

Map<String, Object?> exportJobJson({
  String id = 'job-1',
  String kind = 'manifest',
  String status = 'PENDING',
  String? downloadUrl,
  String? error,
}) => {
  'id': id,
  'kind': kind,
  'status': status,
  'download_url': downloadUrl,
  'error': error,
};

Map<String, Object?> qrEventJson({
  String? fromStatus,
  String toStatus = 'IN_TRANSIT',
  String? milestone,
  String? note,
  DateTime? ts,
}) => {
  'from_status': fromStatus,
  'to_status': toStatus,
  'milestone': milestone,
  'note': note,
  'ts': (ts ?? testNow).toIso8601String(),
};
