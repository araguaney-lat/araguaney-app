import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/push/push_providers.dart';
import '../../../core/push/push_service.dart';

/// Invitación a activar los avisos, con el motivo delante.
///
/// No se pregunta al entrar. Un diálogo del sistema nada más iniciar sesión
/// llega sin contexto y se deniega por reflejo, y en Android una denegación es
/// casi definitiva: la aplicación no puede volver a preguntar. Así que primero
/// se dice qué avisos llegan y quien lee decide si abre el diálogo.
///
/// Desaparece en cuanto hay una decisión, sea cual sea. Denegar no deja una
/// tarjeta insistiendo: quien no los quiere ya lo dijo.
///
/// «Hay una decisión» lo decide [shouldOfferPushProvider] y no el estado que
/// reporta el sistema. En Android ese estado no distingue a quien denegó de
/// quien nunca fue preguntado, y esta tarjeta —que solo se pintaba en el estado
/// `notDetermined`— no llegaba a mostrarse nunca.
class PushPermissionCard extends ConsumerStatefulWidget {
  const PushPermissionCard({super.key});

  @override
  ConsumerState<PushPermissionCard> createState() => _PushPermissionCardState();
}

class _PushPermissionCardState extends ConsumerState<PushPermissionCard> {
  bool _asking = false;

  Future<void> _ask() async {
    setState(() => _asking = true);
    // Se anota antes de preguntar, no después: si el diálogo del sistema mata
    // la aplicación por lo que sea, la persona ya vio la invitación y volver a
    // ponerla delante sería insistir.
    await ref.read(pushPromptMemoryProvider).markOffered();

    final granted =
        await ref.read(pushServiceProvider).requestPermission() ==
        PushPermission.granted;

    // Con el permiso recién concedido puede existir un token que antes no
    // existía —en iOS es el caso normal—, así que se vuelve a registrar el
    // destino. Registrar es idempotente: si ya estaba, no cuesta nada.
    if (granted) await ref.read(onSessionStartedProvider)();

    if (!mounted) return;
    setState(() => _asking = false);
    ref
      ..invalidate(pushPermissionProvider)
      ..invalidate(shouldOfferPushProvider);
  }

  @override
  Widget build(BuildContext context) {
    final offer = ref.watch(shouldOfferPushProvider).valueOrNull ?? false;
    if (!offer) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_none),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Avisos del centro',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Te avisamos cuando se abre una revisión sobre una captura de '
              'este centro y cuando llega un envío que salió de aquí. Nada '
              'más.',
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _asking ? null : _ask,
                child: const Text('Activar avisos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
