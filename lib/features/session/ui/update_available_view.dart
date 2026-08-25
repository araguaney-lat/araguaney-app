import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/client_version_providers.dart';
import '../../../core/i18n/l10n_extension.dart';
import 'app_version_footer.dart';
import 'store_link.dart';

/// Hay una versión más nueva, y la instalada sigue sirviendo.
///
/// **Sale solo al abrir la aplicación, nunca a mitad de un turno.** Un aviso
/// junto a un camión, con alguien escaneando, se descarta sin leerlo — y peor,
/// enseña a descartar, de modo que el día que llegue el muro llega como una
/// sorpresa. Al arrancar, en cambio, todavía no se ha empezado nada y el costo
/// de interrumpir es casi cero. La efectividad de esto no sale de la
/// frecuencia; sale del momento.
///
/// Dice que las capturas en cola sobreviven porque es el miedo real de quien
/// tiene trabajo sin enviar, y sin decirlo «Más tarde» es la única respuesta
/// razonable.
///
/// A diferencia del muro, de aquí **sí se sale**: la versión instalada
/// funciona, y quien decide seguir no está arriesgando nada que el servidor no
/// acepte.
class UpdateAvailableView extends ConsumerWidget {
  const UpdateAvailableView({super.key, required this.latest});

  final String? latest;

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
                    context.l10n.updateAvailableTitle,
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    latest == null
                        ? 'Actualizar te trae las mejoras y los arreglos más '
                              'recientes. Las capturas que tengas guardadas sin '
                              'enviar siguen en el teléfono.'
                        : 'La versión $latest ya está publicada. Las capturas '
                              'que tengas guardadas sin enviar siguen en el '
                              'teléfono.',
                    style: text.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => openStore(context, ref),
                    child: Text(context.l10n.updateAction),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _later(ref),
                    child: Text(context.l10n.updateLaterAction),
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

  Future<void> _later(WidgetRef ref) async {
    // El orden importa: primero se quita de en medio, y el registro del
    // aplazamiento va después. Si escribir en las preferencias fallara, lo peor
    // que pasa es que el aviso vuelva en el próximo arranque —no que la persona
    // se quede mirando una pantalla que no se cierra.
    ref.read(updatePromptDismissedProvider.notifier).state = true;
    if (latest == null) return;
    await ref.read(updatePromptMemoryProvider).snooze(latest!, DateTime.now());
  }
}
