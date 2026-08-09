import 'package:pub_semver/pub_semver.dart';

/// Resultado de comparar la versión instalada con la que el backend soporta.
enum ClientVersionStatus {
  /// La versión instalada sirve y está al día.
  current,

  /// Sirve, pero hay una más nueva publicada.
  updateAvailable,

  /// Ya no sirve: el backend dejó de soportarla y hay que actualizar.
  updateRequired,

  /// No se pudo saber. Nunca bloquea.
  unknown,
}

/// Decide si la aplicación instalada todavía puede hablar con el backend.
///
/// La web se despliega junto al backend; una aplicación instalada no. Puede
/// estar corriendo el binario de hace meses en un centro donde nadie actualiza
/// nada, y sin esta comprobación se rompería sola contra un contrato que
/// cambió. El backend publica los valores en `GET /v1/client/version`.
///
/// Es una función pura sobre tres cadenas de versión a propósito: así se prueba
/// sin red y sin canales de plataforma, y quien la usa decide de dónde saca la
/// versión instalada.
abstract final class ClientVersionGate {
  static ClientVersionStatus evaluate({
    required String currentVersion,
    required String? minSupportedVersion,
    required String? latestVersion,
  }) {
    final current = _tryParse(currentVersion);
    if (current == null) return ClientVersionStatus.unknown;

    final minSupported = _tryParse(minSupportedVersion);
    if (minSupported != null && current < minSupported) {
      return ClientVersionStatus.updateRequired;
    }

    final latest = _tryParse(latestVersion);
    if (latest != null && current < latest) {
      return ClientVersionStatus.updateAvailable;
    }

    // Sin datos utilizables del servidor no se bloquea a nadie: un fallo de la
    // comprobación no puede dejar sin trabajar a un centro. Falla abierta.
    if (minSupported == null && latest == null) {
      return ClientVersionStatus.unknown;
    }

    return ClientVersionStatus.current;
  }

  /// Acepta el formato de `pubspec.yaml` (`1.2.3+4`): el `+4` es metadato de
  /// build y no participa en la comparación de precedencia.
  static Version? _tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return Version.parse(raw);
    } on FormatException {
      return null;
    }
  }
}
