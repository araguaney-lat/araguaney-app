import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nothing a person reads is written in a widget any more, and this is what
/// keeps it that way.
///
/// Phase 31 moved 457 strings behind keys and left a handful behind, which is
/// what happens to a one-off sweep. They were found weeks later by reading the
/// code, not by using the application: a missed string looks perfectly normal
/// in Spanish, and only stops working the day a second language exists.
///
/// So the rule is checked instead of remembered. It is deliberately narrow —
/// accents, Spanish punctuation, and words that cannot be anything else — which
/// costs some recall and buys no false alarms. A check that cries wolf gets an
/// exception added to it, and then it is not a check.
void main() {
  final accents = RegExp(r'[áéíóúÁÉÍÓÚñÑ¿¡«»]');
  final words = RegExp(
    r'\b(caja|cajas|tarima|tarimas|centro|centros|donacion|donante|'
    r'correo|contrasena|usuario|sellada|selladas|sellados|cerrada|cerradas|'
    r'abierta|abiertas|pendiente|pendientes|guardar|aprobar|rechazar|'
    r'entregada|entregado|unidades|incidencia|incidencias|lote|vence|'
    r'ninguna|escribe|hace)\b',
    caseSensitive: false,
  );
  final singleQuoted = RegExp(r"'((?:[^'\\\n]|\\.)*)'");
  final doubleQuoted = RegExp(r'"((?:[^"\\\n]|\\.)*)"');

  /// A literal that is not prose: an identifier, a path, a URL, a query.
  bool isCode(String value) =>
      value.contains('/') ||
      value.contains('_') ||
      RegExp(r'^[A-Z_]+$').hasMatch(value);

  /// A literal inside `Text(...)`, without its interpolations.
  ///
  /// It is the other half of the check, and it does not look for Spanish: it
  /// looks for **prose**. «Recorrido» and «Consultando…» carry no accent and no
  /// word that could not be something else, so the search above did not see
  /// them; what can be asserted is that a sentence written inside a `Text` did
  /// not go through a key, whatever the language.
  final textLiteral = RegExp(r"""Text\(\s*'((?:[^'\\\n]|\\.)*)'""");
  final interpolation = RegExp(r'\$\{[^}]*\}|\$\w+');
  final prose = RegExp(r'[A-Za-zÁÉÍÓÚáéíóúñÑ]{3,}');

  test('no screen carries Spanish of its own', () {
    // A `Set`: the two halves of the check can see the same line, and saying it
    // twice does not make it any truer.
    final offenders = <String>{};

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('generated') ||
          entity.path.endsWith('.g.dart')) {
        continue;
      }

      var lineNumber = 0;
      var inBlockComment = false;
      for (final line in entity.readAsLinesSync()) {
        lineNumber++;
        final trimmed = line.trimLeft();
        if (inBlockComment) {
          if (trimmed.contains('*/')) inBlockComment = false;
          continue;
        }
        if (trimmed.startsWith('/*')) {
          inBlockComment = !trimmed.contains('*/');
          continue;
        }
        if (trimmed.startsWith('//')) continue;

        // A trailing comment on a line of code would otherwise be read as part
        // of it. Anything after `//` outside a string is dropped, crudely but
        // safely: the worst case is checking less of the line.
        final code = line.contains('//') ? line.split('//').first : line;

        // An accent anywhere in a line of code is Spanish, full stop:
        // identifiers are English and comments are already gone. This catches
        // what the literal patterns cannot see — a quoted string **inside** an
        // interpolation, where the outer quotes swallow the boundaries and the
        // inner text falls between two matches. That is exactly how
        // `${item.freeText ?? 'Artículo'}` survived the first sweep.
        if (accents.hasMatch(code)) {
          offenders.add('${entity.path}:$lineNumber → ${code.trim()}');
          continue;
        }

        // What goes inside a `Text` and is not interpolated data is a sentence,
        // and a sentence written here did not go through any key.
        for (final match in textLiteral.allMatches(code)) {
          final written = (match.group(1) ?? '').replaceAll(interpolation, '');
          if (prose.hasMatch(written)) {
            offenders.add('${entity.path}:$lineNumber → ${match.group(1)}');
          }
        }

        for (final pattern in [singleQuoted, doubleQuoted]) {
          for (final match in pattern.allMatches(code)) {
            final value = match.group(1) ?? '';
            if (value.length < 3 || isCode(value)) continue;
            if (!accents.hasMatch(value) && !words.hasMatch(value)) continue;
            offenders.add('${entity.path}:$lineNumber → $value');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These strings belong in app_es.arb behind a key.\n'
          '${offenders.join('\n')}',
    );
  });
}
