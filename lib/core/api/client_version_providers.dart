import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'client_version_gate.dart';
import 'generated/rest_client.dart';
import 'update_prompt_memory.dart';

/// Lo que el backend publica sobre las versiones que soporta.
///
/// Va por el `Dio` **sin sesión**: la ruta es pública, y preguntarla desde el
/// cliente con sesión la ataría a estar dentro, que es justo al revés de lo que
/// hace falta —quien está bloqueado por versión ni siquiera debería poder
/// intentar iniciar sesión.
final _clientVersionApiProvider = Provider(
  (ref) => RestClient(ref.watch(authDioProvider)).client,
);

/// Lo que hay que saber de la versión: en qué estado está y cuál es la última
/// publicada.
///
/// La segunda hace falta para aplazar el aviso **por versión**: sin ella, un
/// «Más tarde» callaría también la publicación siguiente.
typedef ClientVersion = ({ClientVersionStatus status, String? latest});

/// Estado de la versión instalada frente a la que el backend soporta.
///
/// **Se pregunta una vez por arranque y no bloquea nunca por fallar.** El
/// endpoint es una petición más que puede agotar el tiempo en un sótano, y una
/// aplicación que se niega a abrir porque no pudo consultar una versión es peor
/// que una que corre un poco atrasada. Sin respuesta utilizable el resultado es
/// [ClientVersionStatus.unknown], que no interpone nada.
///
/// La decisión de qué hacer con cada estado no vive aquí: esto responde qué
/// pasa, y `SessionGate` decide qué se ve.
final clientVersionStatusProvider = FutureProvider<ClientVersion>((ref) async {
  final installed = ref.watch(appVersionProvider);
  try {
    final published = await ref
        .watch(_clientVersionApiProvider)
        .clientVersionV1ClientVersionGet();
    return (
      status: ClientVersionGate.evaluate(
        currentVersion: installed,
        minSupportedVersion: published.minSupported,
        latestVersion: published.latest,
      ),
      latest: published.latest,
    );
  } on Object {
    // Falla abierta, a propósito: ver arriba.
    return (status: ClientVersionStatus.unknown, latest: null);
  }
});

/// La memoria de los aplazamientos, para que una prueba no toque disco.
final updatePromptMemoryProvider = Provider<UpdatePromptMemory>(
  (ref) => const PrefsUpdatePromptMemory(),
);

/// Si el aviso de «hay una nueva» ya se descartó en este arranque.
///
/// **Es lo que lo mantiene en el arranque y fuera del turno.** Sin esto, el
/// aviso volvería en cuanto la sesión cambiara de estado —al entrar, al cambiar
/// una contraseña obligada— que son justo los momentos en que alguien está
/// haciendo algo.
final updatePromptDismissedProvider = StateProvider<bool>((ref) => false);

/// Si el aviso de la última versión publicada está aplazado.
///
/// Empieza en «sí, calla» mientras se resuelve: un aviso que parpadea al abrir
/// y desaparece es peor que uno que no sale.
final updateSnoozedProvider = FutureProvider<bool>((ref) async {
  final latest = ref.watch(clientVersionStatusProvider).valueOrNull?.latest;
  if (latest == null) return true;
  return ref
      .watch(updatePromptMemoryProvider)
      .isSnoozed(latest, DateTime.now());
});
