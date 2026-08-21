import 'dart:convert';

/// Qué lleva dentro una captura que espera en la cola.
///
/// Se lee del payload guardado y no de una columna nueva porque el payload
/// **es** la captura: exactamente lo que se va a enviar, congelado desde antes
/// del primer intento. Leerlo para enseñarlo no lo reescribe.
///
/// El contrato manda identificadores de producto, no nombres, así que el nombre
/// se resuelve contra el catálogo local. Cuando el catálogo ya no lo tiene se
/// dice solo lo que sí se sabe —la cantidad y su unidad—, porque inventar un
/// nombre para rellenar el hueco es peor que dejarlo corto: quien decide si
/// descarta esta captura necesita datos ciertos, no una línea completa.
List<String> queuedCaptureLines(
  String payload,
  Map<String, String> productNames,
) {
  final boxes = _boxesOf(payload);
  return [for (final box in boxes) _describe(box, productNames)];
}

/// El payload lo escribe esta aplicación, pero es dato en disco: puede venir de
/// una versión anterior o de una fila corrupta, y una pantalla que se cae al
/// leer la cola deja a la persona sin ver lo que no se ha enviado.
List<Map<String, Object?>> _boxesOf(String payload) {
  try {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, Object?>) return const [];
    final boxes = decoded['boxes'];
    if (boxes is! List) return const [];
    return boxes.whereType<Map<String, Object?>>().toList();
  } on FormatException {
    return const [];
  }
}

String _describe(Map<String, Object?> box, Map<String, String> productNames) {
  final quantity = box['quantity'];
  final unit = box['unit'];
  final amount = [
    if (quantity != null) '$quantity',
    if (unit is String && unit.isNotEmpty) unit,
  ].join(' ');

  final id = box['product_type_id'];
  final name = id is String ? productNames[id] : null;
  if (name == null) return amount;
  return amount.isEmpty ? name : '$name — $amount';
}
