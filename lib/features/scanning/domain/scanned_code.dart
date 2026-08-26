/// What a platform QR turned out to be.
///
/// The scan decides nothing about the domain: it only classifies a text so we
/// know who to ask. What each code means is answered by the server.
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

/// A text that is not a platform code. It is kept raw so it can be shown to
/// whoever scanned it: «this is not ours» is a far more useful answer than a
/// generic error.
final class UnrecognizedCode extends ScannedCode {
  const UnrecognizedCode(this.raw);

  final String raw;
}

/// The prefixes the backend mints each code with.
abstract final class CodePrefix {
  static const box = 'BX-';
  static const pallet = 'TM-';
  static const donation = 'DN-';
}

/// The first path segment in the URL the QR encodes.
const _pathKinds = {'b': _Kind.box, 'p': _Kind.pallet, 'd': _Kind.donation};

enum _Kind { box, pallet, donation }

/// Interprets what the camera read.
///
/// It accepts both shapes a label can carry. The QR the backend generates
/// encodes a URL to the public record (`{base}/b/{code}`), but a code typed or
/// printed on its own has to work the same.
///
/// The type is decided by the code's prefix. If the prefix is not recognised
/// but the URL's path already said what it is about, the path wins: that way a
/// label printed before a format change still leads to its record instead of
/// dying in an error.
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

  // The record is always in the last two segments, so a deployment under a
  // path prefix does not break the reading.
  final kind = _pathKinds[segments[segments.length - 2].toLowerCase()];
  if (kind == null) return null;

  return (kind: kind, code: Uri.decodeComponent(segments.last));
}
