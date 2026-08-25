import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/client_version_gate.dart';
import '../../../core/api/client_version_providers.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/i18n/l10n_extension.dart';

/// La versión instalada, al pie.
///
/// **Existe para que preguntar «¿qué versión tienes?» deje de costar una
/// conversación.** Quien opera no sabe —ni tiene por qué— qué compilación le
/// entregó la tienda, y sin este dato diagnosticar cualquier cosa empieza por
/// averiguarlo. Va en el acceso porque es la pantalla que todo el mundo ve
/// antes de poder hacer nada, incluida la persona que todavía no puede entrar.
///
/// Lleva el número de compilación además del nombre: `1.0.0 (3)`. El nombre se
/// repite entre versiones publicadas y el que identifica un binario es el
/// segundo, que es justo el que hace falta para saber qué se está mirando.
class AppVersionFooter extends ConsumerWidget {
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider);
    final build = ref.watch(appBuildNumberProvider);
    // El aviso de actualización disponible vive aquí y no en una tarjeta ni en
    // un diálogo: hay una nueva, no pasa nada por seguir, y una interrupción
    // sería desproporcionada. El muro es otra cosa y tiene su propia pantalla.
    // `valueOrNull`, por lo mismo que en `SessionGate`: `value` relanza sobre
    // un `AsyncError` y tumbaría el acceso entero por no poder consultar una
    // versión.
    final outdated =
        ref.watch(clientVersionStatusProvider).valueOrNull?.status ==
        ClientVersionStatus.updateAvailable;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          build.isEmpty
              ? context.l10n.appVersion(version)
              : context.l10n.appVersionWithBuild(version, build),
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        if (outdated) ...[
          const SizedBox(height: 4),
          Text(
            context.l10n.updateAvailableFooter,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
