/// Lo que un QR de la plataforma resultó ser.
///
/// El escaneo no decide nada del dominio: solo clasifica un texto para saber a
/// quién preguntarle. Qué significa cada código lo contesta el servidor.
sealed class ScannedCode {
  const ScannedCode();
}

final class BoxCode extends ScannedCode {
  const BoxCode(this.code);

  final String code;
}

final class PalletCode extends ScannedCode {
  const PalletCode(this.code);

  final String code;
}

final class DonationCode extends ScannedCode {
  const DonationCode(this.code);

  final String code;
}

/// Un texto que no es un código de la plataforma. Se conserva crudo para
/// poder mostrárselo a quien escaneó: «esto no es nuestro» es una respuesta
/// mucho más útil que un error genérico.
final class UnrecognizedCode extends ScannedCode {
  const UnrecognizedCode(this.raw);

  final String raw;
}

/// Prefijos con los que el backend acuña cada código.
abstract final class CodePrefix {
  static const box = 'BX-';
  static const pallet = 'TM-';
  static const donation = 'DN-';
}

/// Primer segmento de la ruta en la URL que codifica el QR.
const _pathKinds = {'b': _Kind.box, 'p': _Kind.pallet, 'd': _Kind.donation};

enum _Kind { box, pallet, donation }

/// Interpreta lo que leyó la cámara.
///
/// Acepta las dos formas que puede traer una etiqueta. El QR que genera el
/// backend codifica una URL a la ficha pública (`{base}/b/{code}`), pero un
/// código tecleado o impreso suelto tiene que funcionar igual.
///
/// El tipo lo decide el prefijo del código. Si el prefijo no se reconoce pero
/// la ruta de la URL ya dijo de qué se trata, manda la ruta: así una etiqueta
/// impresa antes de un cambio de formato sigue llevando a su ficha en vez de
/// morir en un error.
ScannedCode parseScannedCode(String raw) {
  final payload = raw.trim();
  if (payload.isEmpty) return UnrecognizedCode(raw);

  final fromPath = _kindAndCodeFromUrl(payload);
  final code = fromPath?.code ?? payload;
  if (code.isEmpty) return UnrecognizedCode(raw);

  final kind = _kindFromPrefix(code) ?? fromPath?.kind;

  return switch (kind) {
    _Kind.box => BoxCode(code),
    _Kind.pallet => PalletCode(code),
    _Kind.donation => DonationCode(code),
    null => UnrecognizedCode(raw),
  };
}

_Kind? _kindFromPrefix(String code) {
  final upper = code.toUpperCase();
  if (upper.startsWith(CodePrefix.box)) return _Kind.box;
  if (upper.startsWith(CodePrefix.pallet)) return _Kind.pallet;
  if (upper.startsWith(CodePrefix.donation)) return _Kind.donation;
  return null;
}

({_Kind kind, String code})? _kindAndCodeFromUrl(String payload) {
  final uri = Uri.tryParse(payload);
  if (uri == null || !uri.hasScheme) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length < 2) return null;

  // La ficha va siempre en los dos últimos segmentos, para que un despliegue
  // bajo un prefijo de ruta no rompa la lectura.
  final kind = _pathKinds[segments[segments.length - 2].toLowerCase()];
  if (kind == null) return null;

  return (kind: kind, code: Uri.decodeComponent(segments.last));
}
