import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import 'app_version_footer.dart';
import 'store_link.dart';

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
                    semanticLabel: context.l10n.appTitle,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.updateRequiredTitle,
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.updateRequiredExplanation,
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => openStore(context, ref),
                    child: Text(context.l10n.updateAction),
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
}
