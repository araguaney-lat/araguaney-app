import 'package:pub_semver/pub_semver.dart';

/// The result of comparing the installed version with the one the backend
/// supports.
enum ClientVersionStatus {
  /// The installed version works and is up to date.
  current,

  /// It works, but a newer one has been published.
  updateAvailable,

  /// It no longer works: the backend dropped support and it has to be updated.
  updateRequired,

  /// It could not be known. Never blocks.
  unknown,
}

/// Decides whether the installed application can still talk to the backend.
///
/// The web panel ships alongside the backend; an installed application does
/// not. It may be running a months-old binary in a centre where nobody updates
/// anything, and without this check it would break by itself against a contract
/// that moved. The backend publishes the values at `GET /v1/client/version`.
///
/// It is a pure function over three version strings on purpose: that way it is
/// tested without network and without platform channels, and the caller decides
/// where the installed version comes from.
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

    // With no usable data from the server nobody is blocked: a failure of the
    // check cannot stop a centre working. It fails open.
    if (minSupported == null && latest == null) {
      return ClientVersionStatus.unknown;
    }

    return ClientVersionStatus.current;
  }

  /// Accepts the `pubspec.yaml` format (`1.2.3+4`): the `+4` is build metadata
  /// and takes no part in the precedence comparison.
  static Version? _tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return Version.parse(raw);
    } on FormatException {
      return null;
    }
  }
}
