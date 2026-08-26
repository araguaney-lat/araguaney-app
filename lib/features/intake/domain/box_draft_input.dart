import '../../../core/api/generated/models/box_draft.dart';
import '../../../core/db/app_database.dart';

/// A box under construction inside the capture form.
///
/// That a box has **one** product type, **one** batch and **one** expiry date
/// is not a rule this class imposes: it is the shape of `BoxDraft` in the
/// contract. The interface cannot mix two products in one box because there is
/// nowhere to write the second.
class BoxDraftInput {
  const BoxDraftInput({
    required this.productType,
    required this.quantity,
    required this.unit,
    this.batch,
    this.expiryDate,
    this.weightKg,
    this.code,
    this.gtin,
  });

  /// The product type from the local catalogue, with its name, so the list can
  /// show it without looking it up again.
  final ProductTypeRow productType;
  final int quantity;
  final String unit;
  final String? batch;
  final DateTime? expiryDate;
  final String? weightKg;

  /// A code reserved beforehand. Online the server assigns it; it exists here
  /// because phase 06's offline capture spends reserved codes.
  final String? code;
  final String? gtin;

  BoxDraftInput copyWith({
    ProductTypeRow? productType,
    int? quantity,
    String? unit,
    String? batch,
    DateTime? expiryDate,
    String? weightKg,
    String? code,
    String? gtin,
  }) => BoxDraftInput(
    productType: productType ?? this.productType,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    batch: batch ?? this.batch,
    expiryDate: expiryDate ?? this.expiryDate,
    weightKg: weightKg ?? this.weightKg,
    code: code ?? this.code,
    gtin: gtin ?? this.gtin,
  );

  BoxDraft toRequest() => BoxDraft(
    productTypeId: productType.id,
    quantity: quantity,
    unit: unit,
    batch: batch,
    expiryDate: expiryDate,
    weightKg: weightKg,
    code: code,
    gtin: gtin,
  );
}
