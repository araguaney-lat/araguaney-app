import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n_extension.dart';
import '../data/donations_providers.dart';
import '../data/donations_repository.dart';

/// Lo que el donante fotografió.
///
/// Sirve para el doble check antes de tocar las cajas: una etiqueta que se ve
/// en la foto es una pregunta menos en la puerta. El enlace lo firma el
/// servidor y caduca, así que se pide al abrir y no se guarda.
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

  /// Le pide al servidor que lea la etiqueta.
  ///
  /// Lo que vuelve son **sugerencias**, y así se enseñan: quien tiene el envase
  /// delante las confirma o las corrige. Un diccionario vacío es la respuesta
  /// normal cuando la capacidad está apagada, y se dice sin dramatizar.
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
