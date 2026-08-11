import '../../../core/api/generated/models/box_draft.dart';
import '../../../core/db/app_database.dart';

/// Una caja en construcción dentro del formulario de captura.
///
/// Que una caja tenga **un** tipo de producto, **un** lote y **una** caducidad
/// no es una regla que esta clase imponga: es la forma de `BoxDraft` en el
/// contrato. La interfaz no puede mezclar dos productos en una caja porque no
/// hay dónde escribir el segundo.
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

  /// El tipo de producto del catálogo local, con su nombre, para que la lista
  /// pueda mostrarlo sin volver a consultar.
  final ProductTypeRow productType;
  final int quantity;
  final String unit;
  final String? batch;
  final DateTime? expiryDate;
  final String? weightKg;

  /// Código reservado de antemano. En línea lo asigna el servidor; existe aquí
  /// porque la captura sin conexión de la fase 06 gasta códigos reservados.
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
