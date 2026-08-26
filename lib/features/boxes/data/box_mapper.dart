import '../../../core/api/generated/models/app_schemas_box_box_out.dart';
import '../../../core/db/app_database.dart';

/// Translates the contract's box into the local row, field by field.
///
/// `status` travels as text without being interpreted: what each state means is
/// a backend rule, and translating it here would mean keeping two versions of
/// it.
BoxRow toBoxRow(AppSchemasBoxBoxOut out) => BoxRow(
  id: out.id,
  code: out.code,
  centerId: out.centerId,
  productTypeId: out.productTypeId,
  quantity: out.quantity,
  unit: out.unit,
  status: out.status,
  batch: out.batch,
  expiryDate: out.expiryDate,
  weightKg: out.weightKg,
  sealedAt: out.sealedAt,
  palletId: out.palletId,
  intakeId: out.intakeId,
  rejectReason: out.rejectReason,
  createdAt: out.createdAt,
);
