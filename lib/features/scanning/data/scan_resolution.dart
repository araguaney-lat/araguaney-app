import '../../../core/api/api_failure.dart';
import '../../../core/api/generated/models/box_public_out.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/pallet_public_out.dart';
import '../../../core/db/app_database.dart';

/// Where a scan leads.
sealed class ScanResolution {
  const ScanResolution();
}

/// The box was in the cache: the operator's record opens, complete, and it
/// works without signal.
final class CachedBoxFound extends ScanResolution {
  const CachedBoxFound(this.box);

  final BoxRow box;
}

/// The box was not cached and was resolved through the public record.
///
/// It brings less than the operator's record. The screen says so: the
/// difference between «this is all there is» and «this is what could be looked
/// up» changes what somebody decides with it in front of them.
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

/// The text that was read is not a platform code.
final class ScanNotRecognized extends ScanResolution {
  const ScanNotRecognized(this.raw);

  final String raw;
}

/// The code looks valid but could not be resolved: no signal, no permission, or
/// the server does not know it.
final class ScanResolutionFailed extends ScanResolution {
  const ScanResolutionFailed(this.failure);

  final ApiFailure failure;
}
