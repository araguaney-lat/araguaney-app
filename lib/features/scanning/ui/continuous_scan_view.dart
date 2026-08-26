import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../domain/scan_throttle.dart';
import 'scanner_camera.dart';

/// What happened to a read.
class ScanFeedback {
  const ScanFeedback.accepted(this.message) : accepted = true;
  const ScanFeedback.rejected(this.message) : accepted = false;

  final bool accepted;
  final String message;
}

/// Scanning one label after another without leaving the camera.
///
/// It is how whoever builds a pallet works: the boxes are stacked, their hands
/// are full, and going back to a list between one box and the next turns two
/// minutes into ten. Each read leaves a line in the log with what the server
/// said, accepted or refused, so nobody has to remember where they were.
class ContinuousScanView extends StatefulWidget {
  const ContinuousScanView({
    super.key,
    required this.title,
    required this.hint,
    required this.onScanned,
  });

  final String title;
  final String hint;

  /// What to do with each read. It is called one at a time: while one is in
  /// progress, the following ones are ignored.
  final Future<ScanFeedback> Function(String payload) onScanned;

  static Route<void> route({
    required String title,
    required String hint,
    required Future<ScanFeedback> Function(String payload) onScanned,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        ContinuousScanView(title: title, hint: hint, onScanned: onScanned),
  );

  @override
  State<ContinuousScanView> createState() => _ContinuousScanViewState();
}

class _ContinuousScanViewState extends State<ContinuousScanView> {
  final _controller = ScannerCamera.buildController();
  final _throttle = ScanThrottle();
  final _log = <ScanFeedback>[];

  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;

    final payload = capture.barcodes
        .map((Barcode barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (payload == null || !_throttle.accepts(payload)) return;

    _busy = true;
    // The vibration comes before the result is known: it confirms the read
    // happened, which is what whoever is pointing needs to know at that
    // instant.
    await HapticFeedback.selectionClick();

    final feedback = await widget.onScanned(payload);
    if (!mounted) return;

    setState(() => _log.insert(0, feedback));
    _busy = false;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        IconButton(
          tooltip: context.l10n.scanTorch,
          icon: const Icon(Icons.flashlight_on_outlined),
          onPressed: _controller.toggleTorch,
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          flex: 3,
          child: ScannerCamera(
            controller: _controller,
            onDetect: _onDetect,
            overlay: ScannerHint(widget.hint),
          ),
        ),
        Expanded(
          flex: 2,
          child: _log.isEmpty
              ? const _EmptyLog()
              : ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (context, index) => _LogLine(entry: _log[index]),
                ),
        ),
      ],
    ),
  );
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final ScanFeedback entry;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: Icon(
      entry.accepted ? Icons.check_circle_outline : Icons.error_outline,
      color: entry.accepted ? null : Theme.of(context).colorScheme.error,
    ),
    title: Text(entry.message),
  );
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        context.l10n.scanContinuousExplanation,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}
