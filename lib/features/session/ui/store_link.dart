import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/platform/open_link.dart';

/// Abre la ficha de esta aplicación en la tienda.
///
/// Lo usan las dos pantallas de versión —el muro y el aviso— y por eso vive
/// aparte: la de arriba no es la clase de lógica que conviene tener dos veces,
/// porque el día que cambie el esquema cambiaría en una sola.
///
/// `market://` lo atiende la tienda instalada sin pasar por el navegador. Si no
/// hay ninguna que lo resuelva —un emulador sin Play, un dispositivo sin
/// servicios de Google— se cae a la ficha web, que también sirve.
Future<void> openStore(BuildContext context, WidgetRef ref) async {
  final package = ref.read(appPackageNameProvider);
  final open = ref.read(openLinkProvider);

  if (await open('market://details?id=$package')) return;
  if (!context.mounted) return;

  final opened = await open(
    'https://play.google.com/store/apps/details?id=$package',
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.sessionNoSePudoAbrirLa)),
    );
  }
}
