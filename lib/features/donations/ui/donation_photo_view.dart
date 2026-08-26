import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../data/donations_providers.dart';
import '../data/donations_repository.dart';

/// What the donor photographed.
///
/// It serves for the double check before touching the boxes: a label visible in
/// the photo is one question fewer at the door. The link is signed by the
/// server and expires, so it is asked for on opening and not stored.
class DonationPhotoView extends ConsumerStatefulWidget {
  const DonationPhotoView({
    super.key,
    required this.code,
    required this.photoId,
  });

  final String code;
  final String photoId;

  static Route<void> route({required String code, required String photoId}) =>
      MaterialPageRoute<void>(
        builder: (_) => DonationPhotoView(code: code, photoId: photoId),
      );

  @override
  ConsumerState<DonationPhotoView> createState() => _DonationPhotoViewState();
}

class _DonationPhotoViewState extends ConsumerState<DonationPhotoView> {
  Map<String, String>? _read;
  bool _reading = false;

  /// Asks the server to read the label.
  ///
  /// What comes back are **suggestions**, and that is how they are shown:
  /// whoever has the package in front of them confirms or corrects them. An
  /// empty dictionary is the normal answer when the capability is off, and it
  /// is said without drama.
  Future<void> _readLabel() async {
    setState(() => _reading = true);
    final outcome = await ref
        .read(donationsRepositoryProvider)
        .readLabel(code: widget.code, photoId: widget.photoId);
    if (!mounted) return;

    setState(() {
      _reading = false;
      _read = switch (outcome) {
        DonationsRead(:final value) => value,
        DonationsRefused() => const {},
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = ref.watch(
      donationPhotoUrlProvider((code: widget.code, photoId: widget.photoId)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.donationPhotoTitle)),
      body: ListView(
        children: [
          switch (url) {
            AsyncData(value: DonationsRead(:final value)) => Image.network(
              value,
              fit: BoxFit.contain,
              errorBuilder: (context, _, _) =>
                  _Message(context.l10n.donationPhotoUnavailable),
            ),
            AsyncData(value: DonationsRefused(:final failure)) => _Message(
              failure.operatorMessage(context.l10n),
            ),
            AsyncError() => _Message(context.l10n.donationPhotoUnavailable),
            _ => const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _reading ? null : _readLabel,
              icon: const Icon(Icons.text_fields),
              label: Text(context.l10n.donationReadLabelAction),
            ),
          ),
          if (_read case final fields?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: fields.isEmpty
                  ? Text(context.l10n.donationLabelUnread)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.donationLabelSuggestions,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        for (final field in fields.entries)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(field.key),
                            subtitle: Text(field.value),
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Text(text, textAlign: TextAlign.center),
  );
}
