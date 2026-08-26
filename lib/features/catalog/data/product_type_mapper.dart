import '../../../core/api/generated/models/product_type_out.dart';
import '../../../core/db/app_database.dart';

/// Translates the contract's product type into the local row.
///
/// It is a field-by-field copy on purpose: nothing is computed, nothing is
/// dropped and nothing is decided. What the server served is what gets stored.
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
