import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'client_version_gate.dart';
import 'generated/rest_client.dart';

/// Lo que el backend publica sobre las versiones que soporta.
///
/// Va por el `Dio` **sin sesión**: la ruta es pública, y preguntarla desde el
/// cliente con sesión la ataría a estar dentro, que es justo al revés de lo que
/// hace falta —quien está bloqueado por versión ni siquiera debería poder
/// intentar iniciar sesión.
final _clientVersionApiProvider = Provider(
  (ref) => RestClient(ref.watch(authDioProvider)).client,
);

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
final clientVersionStatusProvider = FutureProvider<ClientVersionStatus>((
  ref,
) async {
  final installed = ref.watch(appVersionProvider);
  try {
    final published = await ref
        .watch(_clientVersionApiProvider)
        .clientVersionV1ClientVersionGet();
    return ClientVersionGate.evaluate(
      currentVersion: installed,
      minSupportedVersion: published.minSupported,
      latestVersion: published.latest,
    );
  } on Object {
    // Falla abierta, a propósito: ver arriba.
    return ClientVersionStatus.unknown;
  }
});
