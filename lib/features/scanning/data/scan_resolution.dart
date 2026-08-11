import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/models/box_public_out.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/pallet_public_out.dart';
import '../../../core/db/app_database.dart';

/// A dónde lleva un escaneo.
sealed class ScanResolution {
  const ScanResolution();
}

/// La caja estaba en el cache: se abre la ficha del operador, la completa, y
/// funciona sin señal.
final class CachedBoxFound extends ScanResolution {
  const CachedBoxFound(this.box);

  final BoxRow box;
}

/// La caja no estaba cacheada y se resolvió por la ficha pública.
///
/// Trae menos que el registro del operador. La pantalla lo dice: la diferencia
/// entre «esto es todo lo que hay» y «esto es lo que se pudo consultar» cambia
/// lo que alguien decide con ella delante.
final class PublicBoxFound extends ScanResolution {
  const PublicBoxFound(this.box);

  final BoxPublicOut box;
}

final class PublicPalletFound extends ScanResolution {
  const PublicPalletFound(this.pallet);

  final PalletPublicOut pallet;
}

final class DonationFound extends ScanResolution {
  const DonationFound(this.donation);

  final DonationOut donation;
}

/// El texto leído no es un código de la plataforma.
final class ScanNotRecognized extends ScanResolution {
  const ScanNotRecognized(this.raw);

  final String raw;
}

/// El código parece válido pero no se pudo resolver: sin señal, sin permiso o
/// el servidor no lo conoce.
final class ScanResolutionFailed extends ScanResolution {
  const ScanResolutionFailed(this.failure);

  final ApiFailure failure;
}
