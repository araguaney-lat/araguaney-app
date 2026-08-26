/// How what the reader returns becomes the number that is looked up.
///
/// There are only two transformations, and neither decides anything about the
/// domain: dropping whatever is not a digit, and expanding a UPC-E. Which
/// product that number is, the catalogue answers.
library;

/// A read's GTIN, or null if it carried no digits.
///
/// [compressed] says the reader recognised the symbol as a **UPC-E**, which is
/// the only way to know: a UPC-E and an EAN-8 have the same eight digits and
/// only the symbol's format tells them apart.
String? gtinFromScan(String raw, {required bool compressed}) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (compressed && digits.length == 8) return expandUpcE(digits);
  return digits;
}

/// Expands an eight-digit UPC-E into the twelve-digit UPC-A it stands for.
///
/// A UPC-E is a UPC-A with runs of zeros suppressed so it fits on a small
/// package — a tube, a single dose — and the sixth data digit says which of the
/// four suppressions was applied. The expansion is the symbol's definition, not
/// an interpretation: there is exactly one answer.
///
/// It is needed because a UPC-E's check digit **does not add up over its eight
/// digits**: it was computed over the expanded UPC-A. Sending it unexpanded
/// produces a scan that looks as though it went fine and that the server
/// refuses later.
///
/// It returns the original if it does not have the shape of a UPC-E; there is
/// nothing to invent when the data is not what was expected.
String expandUpcE(String upcE) {
  if (upcE.length != 8) return upcE;

  final system = upcE[0];
  // A UPC-E's number system can only be 0 or 1.
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
