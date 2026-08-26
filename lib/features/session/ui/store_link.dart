import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/platform/open_link.dart';

/// Opens this application's page in the store.
///
/// Both version screens use it — the wall and the notice — and that is why it
/// lives apart: what is above is not the kind of logic worth having twice,
/// because the day the scheme changes it would change in only one of them.
///
/// `market://` is handled by the installed store without going through the
/// browser. If nothing resolves it — an emulator with no Play, a device without
/// Google services — it falls back to the web page, which also works.
Future<void> openStore(BuildContext context, WidgetRef ref) async {
  final package = ref.read(appPackageNameProvider);
  final open = ref.read(openLinkProvider);

  if (await open('market://details?id=$package')) return;
  if (!context.mounted) return;

  final opened = await open(
    'https://play.google.com/store/apps/details?id=$package',
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.storeOpenFailed)));
  }
}
