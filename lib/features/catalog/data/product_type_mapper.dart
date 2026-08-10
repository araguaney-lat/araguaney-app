import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/db/app_database.dart';

/// Traduce el tipo de producto del contrato a la fila local.
///
/// Es una copia campo a campo a propósito: no se calcula nada, no se descarta
/// nada y no se decide nada. Lo que el servidor sirvió es lo que se guarda.
ProductTypeRow toProductTypeRow(ProductTypeOut out) => ProductTypeRow(
  id: out.id,
  displayName: out.displayName,
  category: out.category,
  brand: out.brand,
  form: out.form,
  strength: out.strength,
  defaultUnit: out.defaultUnit,
  gtin: out.gtin,
  innName: out.innName,
  isControlled: out.isControlled,
  minShelfLifeDays: out.minShelfLifeDays,
  unitWeightKg: out.unitWeightKg,
  unspscCode: out.unspscCode,
  campaignId: out.campaignId,
  createdAt: out.createdAt,
);
