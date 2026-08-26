import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/i18n/l10n_extension.dart';

/// A box's label, drawn on the device.
///
/// The QR is generated here and not asked of the server for an operational
/// reason: a box is labelled at the moment it is sealed, and that moment can
/// happen without signal. The batch PDF is still the server's, which is where
/// it makes sense.
///
/// The content replicates exactly what the backend generates: if the two labels
/// of the same box led to different places, whoever receives it would see one
/// record and whoever dispatched it another.
class BoxLabelView extends StatelessWidget {
  const BoxLabelView({super.key, required this.code});

  final String code;

  static Route<void> route(String code) =>
      MaterialPageRoute<void>(builder: (_) => BoxLabelView(code: code));

  /// What is encoded in the QR. Exposed publicly so a test can check it without
  /// rendering.
  static String payloadFor(String code) =>
      '${AppConfig.webBaseUrl.replaceAll(RegExp(r'/+$'), '')}/b/$code';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(code)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // An explicit white background: on a dark theme a QR with no
            // background becomes unreadable for the camera that reads it.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: payloadFor(code),
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SelectableText(code, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              context.l10n.boxLabelInstruction,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}
