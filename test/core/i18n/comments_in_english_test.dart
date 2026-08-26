import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The ratchet for Phase 32.
///
/// Translating 3,348 lines of comments takes several sessions, and code keeps
/// being written meanwhile. Without this, the work competes with its own
/// growth: every new phase adds Spanish comments faster than the old ones are
/// cleaned — which is exactly what happened between the phase being measured at
/// 2,697 lines and today.
///
/// So the list of files with Spanish **can only shrink**:
///
/// - a file that is not on it and carries a Spanish comment fails, and that is
///   what stops the number going up again;
/// - a file that **is** on it and no longer carries one fails too, asking for
///   the line to be deleted. Without that half the list goes on claiming
///   something that stopped being true, which is how an exception list turns
///   into noise.
///
/// Quotations do not count. The phase says they stay — they are what somebody
/// said, not prose about it — so anything between guillemets is dropped before
/// looking. Code in backticks is dropped for the same reason: an identifier or
/// a literal cited in a comment is evidence about the code, and the one place
/// it matters is the check next door, which quotes the very string that got
/// past it — `${item.freeText ?? 'Artículo'}`.
void main() {
  final quoted = RegExp('«[^»]*»|“[^”]*”|`[^`]*`');
  // «no» and «solo» are left out on purpose: they are ordinary English words —
  // «no longer», «solo» — and with them in, the check accuses itself. What is
  // left is accents and words that cannot be anything else.
  final spanish = RegExp(
    r'[áéíóúñÁÉÍÓÚÑ¿¡]|'
    r'\b(el|la|los|las|un|una|de|que|se|por|para|con|es|son|sin|esto|'
    r'esta|pero|porque|cuando|donde|como|hay|ya|lo|al|del|su|sus|le|les|'
    r'dos|cada|desde|hasta|mismo|misma|nada|todo|toda)\b',
    caseSensitive: false,
  );

  bool hasSpanishComments(File file) => file.readAsLinesSync().any((line) {
    final trimmed = line.trimLeft();
    if (!trimmed.startsWith('//')) return false;
    return spanish.hasMatch(trimmed.replaceAll(quoted, ''));
  });

  List<String> sourceFiles() => [
    for (final scope in ['lib', 'test'])
      for (final entity in Directory(scope).listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.endsWith('.g.dart') &&
            !entity.path.contains('generated'))
          entity.path,
  ];

  test('no new Spanish comment is added, and the list only shrinks', () {
    final listed = File('test/spanish_comments.txt')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toSet();

    final added = <String>[];
    final cleaned = <String>[];

    for (final path in sourceFiles()) {
      final spanishHere = hasSpanishComments(File(path));
      if (spanishHere && !listed.contains(path)) added.add(path);
      if (!spanishHere && listed.contains(path)) cleaned.add(path);
    }

    expect(
      added,
      isEmpty,
      reason:
          'These files have Spanish comments and are not on the list. Write '
          'them in English rather than adding them to it — the list is the '
          'backlog, not an exception mechanism.\n${added.join('\n')}',
    );

    expect(
      cleaned,
      isEmpty,
      reason:
          'These files no longer have Spanish comments. Remove their lines '
          'from test/spanish_comments.txt so the list keeps telling the '
          'truth.\n${cleaned.join('\n')}',
    );
  });

  test('the list names files that exist', () {
    // A renamed or deleted file leaves a line that protects nothing and that
    // nobody will remove on their own.
    final missing = File('test/spanish_comments.txt')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .where((path) => !File(path).existsSync())
        .toList();

    expect(missing, isEmpty, reason: missing.join('\n'));
  });
}
