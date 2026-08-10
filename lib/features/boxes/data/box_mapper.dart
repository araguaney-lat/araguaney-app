import '../../../core/api/generated/models/app_schemas_box_box_out.dart';
import '../../../core/db/app_database.dart';

/// Traduce la caja del contrato a la fila local, campo a campo.
///
/// `status` viaja como texto sin interpretarse: qué significa cada estado es
/// una regla del backend, y traducirla aquí sería mantener dos versiones de
/// ella.
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
