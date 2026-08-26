import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/generated/app_localizations.dart';
import '../../../core/i18n/l10n_extension.dart';

/// The camera, with its permission handling and its torch.
///
/// It exists because two screens scan and their differences are in what they do
/// with what was read, not in how to read it. What is shared matters: the text
/// somebody is shown when the permission is denied has to be the same on both,
/// and duplicating it guarantees that one day they will stop being so.
class ScannerCamera extends StatelessWidget {
  const ScannerCamera({
    super.key,
    required this.controller,
    required this.onDetect,
    this.overlay,
  });

  final MobileScannerController controller;
  final void Function(BarcodeCapture capture) onDetect;

  /// What is painted over the image: a hint, a log of reads.
  final Widget? overlay;

  /// Each screen declares what it expects to read, and the decoder tries
  /// nothing else. It is not a check made afterwards: a format that is not on
  /// the list does not produce a wrong read, it produces none.
  ///
  /// That is why the box and pallet scanner stays on QR. A cardboard box also
  /// carries the manufacturer's barcode, and accepting it would mean pointing
  /// at our label could return the laboratory's — a false hit, which is worse
  /// than a clear failure.
  ///
  /// `noDuplicates` avoids repeating the same read while the phone is still
  /// over the label.
  static MobileScannerController buildController({
    List<BarcodeFormat> formats = const [BarcodeFormat.qrCode],
  }) => MobileScannerController(
    formats: formats,
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  /// What is read on a product's package.
  ///
  /// The four linear ones cover the world's two systems: EAN-13 and EAN-8
  /// outside North America — Mexico is `750`, Venezuela `759` — and UPC-A and
  /// UPC-E in the United States and Canada, where much of what is donated comes
  /// from.
  ///
  /// **UPC-E is expanded before it is looked up** (`gtinFromScan`): its check
  /// digit was computed over the twelve-digit UPC-A it came from, so sending it
  /// compressed produces a scan that looks fine and that the server refuses.
  ///
  /// **DataMatrix is not there**: it appeared on no package in the sample, and
  /// accepting it without interpreting the GS1 identifiers would send the wrong
  /// digits.
  ///
  /// QR is on the list but is never looked up: it is there so we can say what
  /// was read. On a package the QR is usually the laboratory's — it carries
  /// their logo inside — and does not identify the product; and it may also be
  /// a label of ours. Without reading it, pointing there would do nothing, and
  /// doing nothing is the worst possible answer when you cannot tell whether
  /// the camera or your aim is at fault.
  static const productFormats = [
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.qrCode,
  ];

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      MobileScanner(
        controller: controller,
        onDetect: onDetect,
        errorBuilder: (context, error) =>
            ScannerError(error: error, onRetry: controller.start),
      ),
      ?overlay,
    ],
  );
}

/// With no camera there is no screen worth having: instead of a black
/// rectangle, what is missing is said and a retry is offered.
class ScannerError extends StatelessWidget {
  const ScannerError({super.key, required this.error, required this.onRetry});

  final MobileScannerException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.no_photography_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            _message(context.l10n),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => onRetry(),
            child: Text(context.l10n.actionRetry),
          ),
        ],
      ),
    ),
  );

  String _message(AppLocalizations l10n) => switch (error.errorCode) {
    MobileScannerErrorCode.permissionDenied => l10n.cameraPermissionDenied,
    MobileScannerErrorCode.unsupported => l10n.cameraUnsupported,
    _ => l10n.cameraFailed,
  };
}

/// A bottom strip with the screen's instruction.
class ScannerHint extends StatelessWidget {
  const ScannerHint(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      width: double.infinity,
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}
