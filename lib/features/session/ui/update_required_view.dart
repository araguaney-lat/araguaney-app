import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/platform/open_link.dart';
import 'app_version_footer.dart';

/// El muro: esta compilación ya no la soporta el backend.
///
/// **Es la única pantalla de la aplicación de la que no se sale.** No hay
/// flecha atrás, no hay «continuar de todos modos» y no hay forma de llegar al
/// acceso, porque el contrato ya no garantiza que lo que esta versión mande se
/// entienda igual. Dejar seguir «bajo tu responsabilidad» trasladaría a quien
/// opera una decisión que no tiene cómo evaluar, y el costo de equivocarse lo
/// paga el inventario de un centro.
///
/// Solo se llega aquí cuando el servidor lo dijo. Un fallo de la comprobación
/// nunca trae a nadie a esta pantalla: ver `clientVersionStatusProvider`.
class UpdateRequiredView extends ConsumerWidget {
  const UpdateRequiredView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/icon/ic_mark_lg.png',
                    height: 72,
                    fit: BoxFit.fitHeight,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: 'Araguaney',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Esta versión ya no funciona',
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Actualiza Araguaney para seguir operando tu centro. '
                    'Las capturas que tengas guardadas sin enviar siguen en '
                    'el teléfono y se envían cuando actualices.',
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => _openStore(context, ref),
                    child: const Text('Actualizar'),
                  ),
                  const SizedBox(height: 24),
                  const AppVersionFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, WidgetRef ref) async {
    final package = ref.read(appPackageNameProvider);
    // `market://` lo abre la tienda instalada sin pasar por el navegador. Si no
    // hay ninguna que lo atienda —un emulador sin Play, un dispositivo sin
    // servicios de Google— se cae a la ficha web, que también sirve.
    final opened = await ref.read(openLinkProvider)(
      'market://details?id=$package',
    );
    if (opened || !context.mounted) return;

    final fallback = await ref.read(openLinkProvider)(
      'https://play.google.com/store/apps/details?id=$package',
    );
    if (!fallback && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo abrir la tienda. Búscala como «Araguaney».',
          ),
        ),
      );
    }
  }
}
