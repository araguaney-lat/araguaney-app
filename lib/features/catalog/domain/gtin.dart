/// Cómo se convierte lo que devuelve el lector en el número que se consulta.
///
/// Solo hay dos transformaciones, y ninguna decide nada del dominio: quitar lo
/// que no es un dígito, y expandir un UPC-E. Qué producto es ese número lo
/// contesta el catálogo.
library;

/// El GTIN de una lectura, o nulo si no llevaba dígitos.
///
/// [compressed] indica que el lector reconoció el símbolo como **UPC-E**, que
/// es la única forma de saberlo: un UPC-E y un EAN-8 tienen los mismos ocho
/// dígitos y solo el formato del símbolo los distingue.
String? gtinFromScan(String raw, {required bool compressed}) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (compressed && digits.length == 8) return expandUpcE(digits);
  return digits;
}

/// Expande un UPC-E de ocho dígitos al UPC-A de doce que representa.
///
/// Un UPC-E es un UPC-A al que se le han suprimido carreras de ceros para caber
/// en un envase pequeño —un tubo, una monodosis—, y el sexto dígito de datos
/// dice cuál de las cuatro supresiones se aplicó. La expansión es la definición
/// del símbolo, no una interpretación: existe una sola respuesta.
///
/// Hace falta porque el dígito de control de un UPC-E **no cuadra sobre sus
/// ocho dígitos**: se calculó sobre el UPC-A expandido. Mandarlo sin expandir
/// produce un escaneo que parece haber ido bien y que el servidor rechaza
/// después.
///
/// Devuelve el original si no tiene la forma de un UPC-E; no hay nada que
/// inventar cuando el dato no es el que se esperaba.
String expandUpcE(String upcE) {
  if (upcE.length != 8) return upcE;

  final system = upcE[0];
  // El sistema numérico de un UPC-E solo puede ser 0 o 1.
  if (system != '0' && system != '1') return upcE;

  final d = upcE.substring(1, 7);
  final check = upcE[7];

  final body = switch (d[5]) {
    '0' ||
    '1' ||
    '2' => '$system${d[0]}${d[1]}${d[5]}0000${d[2]}${d[3]}${d[4]}',
    '3' => '$system${d[0]}${d[1]}${d[2]}00000${d[3]}${d[4]}',
    '4' => '$system${d[0]}${d[1]}${d[2]}${d[3]}00000${d[4]}',
    _ => '$system${d[0]}${d[1]}${d[2]}${d[3]}${d[4]}0000${d[5]}',
  };

  return '$body$check';
}
