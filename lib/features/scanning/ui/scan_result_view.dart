import 'package:flutter/material.dart';

import '../../../core/api/generated/models/box_public_out.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/pallet_public_out.dart';
import '../../../core/ui/record_field.dart';
import '../../boxes/ui/box_status_label.dart';
import '../data/scan_resolution.dart';

/// Lo que se ve después de escanear, salvo cuando la caja estaba cacheada: en
/// ese caso se abre su ficha de operador, que trae más.
class ScanResultView extends StatelessWidget {
  const ScanResultView({super.key, required this.resolution});

  final ScanResolution resolution;

  static Route<void> route(ScanResolution resolution) =>
      MaterialPageRoute<void>(
        builder: (_) => ScanResultView(resolution: resolution),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_title)),
    body: switch (resolution) {
      PublicBoxFound(:final box) => _PublicBoxFields(box: box),
      PublicPalletFound(:final pallet) => _PalletFields(pallet: pallet),
      DonationFound(:final donation) => _DonationFields(donation: donation),
      ScanNotRecognized(:final raw) => _Message(
        icon: Icons.help_outline,
        text: 'Este código no es de Araguaney. Se leyó:\n\n$raw',
      ),
      ScanResolutionFailed(:final failure) => _Message(
        icon: Icons.error_outline,
        text: failure.operatorMessage,
      ),
      // La caja cacheada no llega aquí: la pantalla del escáner abre su ficha
      // directamente. El caso existe para que el switch sea total.
      CachedBoxFound(:final box) => _Message(
        icon: Icons.inventory_2_outlined,
        text: 'Caja ${box.code}',
      ),
    },
  );

  String get _title => switch (resolution) {
    PublicBoxFound(:final box) => box.code,
    PublicPalletFound(:final pallet) => pallet.code,
    DonationFound(:final donation) => donation.code,
    CachedBoxFound(:final box) => box.code,
    _ => 'Código escaneado',
  };
}

/// La ficha pública de una caja trae menos que el registro del operador. El
/// aviso de arriba lo dice: quien la lee tiene que saber que está viendo lo
/// que ve cualquiera que escanee la etiqueta, no el detalle interno.
class _PublicBoxFields extends StatelessWidget {
  const _PublicBoxFields({required this.box});

  final BoxPublicOut box;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      const _Notice(
        'Esta caja no está descargada en el dispositivo. Se muestra su ficha '
        'pública, que trae menos datos que el registro del centro.',
      ),
      RecordField(label: 'Estado', value: boxStatusLabel(box.status)),
      RecordField(label: 'Producto', value: box.displayName),
      RecordField(label: 'Categoría', value: box.category),
      RecordField(label: 'Cantidad', value: '${box.quantity} ${box.unit}'),
      if (box.expiryDate case final expiry?)
        RecordField(label: 'Caducidad', value: formatShortDate(expiry)),
      if (box.sealedAt case final sealed?)
        RecordField(label: 'Fecha de sellado', value: formatShortDate(sealed)),
      if (box.deliveredAt case final delivered?)
        RecordField(
          label: 'Fecha de entrega',
          value: formatShortDate(delivered),
        ),
    ],
  );
}

class _PalletFields extends StatelessWidget {
  const _PalletFields({required this.pallet});

  final PalletPublicOut pallet;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      RecordField(label: 'Estado', value: pallet.status),
      RecordField(label: 'Centro', value: pallet.centerName),
      RecordField(label: 'Cajas', value: '${pallet.boxCount}'),
      if (pallet.closedAt case final closed?)
        RecordField(label: 'Fecha de cierre', value: formatShortDate(closed)),
      if (pallet.deliveredAt case final delivered?)
        RecordField(
          label: 'Fecha de entrega',
          value: formatShortDate(delivered),
        ),
    ],
  );
}

class _DonationFields extends StatelessWidget {
  const _DonationFields({required this.donation});

  final DonationOut donation;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.symmetric(vertical: 8),
    children: [
      const _Notice(
        'Registrar la recepción de esta donación llega con la captura, en una '
        'fase siguiente. Por ahora se consulta.',
      ),
      RecordField(label: 'Estado', value: donation.status),
      RecordField(
        label: 'Registrada',
        value: formatShortDate(donation.createdAt),
      ),
      RecordField(label: 'Artículos', value: '${donation.items.length}'),
      for (final item in donation.items)
        RecordField(
          label: item.freeText ?? 'Artículo',
          value: '${item.quantity} ${item.unit}',
        ),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}
