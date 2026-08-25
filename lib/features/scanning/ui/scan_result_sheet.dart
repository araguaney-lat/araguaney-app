import 'package:flutter/material.dart';

import '../../../core/api/generated/models/box_public_out.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/pallet_public_out.dart';
import '../../../core/db/app_database.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../../core/ui/category_label.dart';
import '../../../core/ui/confirm_button.dart';
import '../../../core/ui/record_field.dart';
import '../../../core/ui/sheet_insets.dart';
import '../../../core/ui/status_labels.dart';
import '../data/scan_resolution.dart';

/// Lo que se leyó, sobre la cámara.
///
/// Era una pantalla aparte y ahora es una hoja: quien comprueba una tarima
/// escanea una caja tras otra, y cada respuesta costaba entrar y salir de una
/// pantalla. Cerrando la hoja se vuelve a estar apuntando.
///
/// La hoja identifica; no sustituye a la ficha. Cuando hay una ficha con
/// acciones detrás —la de operador de una caja cacheada, la captura de una
/// donación— la hoja lleva a ella con un botón.
class ScanResultSheet extends StatelessWidget {
  const ScanResultSheet({
    super.key,
    required this.resolution,
    this.onOpen,
    this.productName,
  });

  final ScanResolution resolution;

  /// El nombre del producto de una caja cacheada. La fila de la caja solo
  /// guarda el identificador del tipo, así que lo resuelve quien abre la hoja
  /// contra el catálogo local; es nulo cuando el catálogo ya no lo tiene, y
  /// entonces no se enseña nada en vez de un identificador.
  final String? productName;

  /// Qué hacer con la acción principal, cuando la hay. La decide quien abre la
  /// hoja porque es navegación, y la hoja no sabe de dónde se la llamó.
  final VoidCallback? onOpen;

  static Future<void> show(
    BuildContext context, {
    required ScanResolution resolution,
    VoidCallback? onOpen,
    String? productName,
  }) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ScanResultSheet(
      resolution: resolution,
      onOpen: onOpen,
      productName: productName,
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(16, 0, 16, sheetBottomInset(context)),
    child: switch (resolution) {
      CachedBoxFound(:final box) => _CachedBox(
        box: box,
        productName: productName,
        onOpen: onOpen,
      ),
      PublicBoxFound(:final box) => _PublicBox(box: box),
      PublicPalletFound(:final pallet) => _Pallet(pallet: pallet),
      DonationFound(:final donation) => _Donation(
        donation: donation,
        onOpen: onOpen,
      ),
      ScanNotRecognized(:final raw) => _Message(
        icon: Icons.help_outline,
        title: context.l10n.scanningEsteCodigoNoEsDe,
        text: 'Se leyó:\n\n$raw',
      ),
      ScanResolutionFailed(:final failure) => _Message(
        icon: Icons.error_outline,
        title: context.l10n.scanningNoSePudoConsultar,
        text: failure.operatorMessage(context.l10n),
      ),
    },
  );
}

/// Encabezado común: el código como está impreso en la etiqueta, y su estado.
class _Headline extends StatelessWidget {
  const _Headline({required this.code, this.status});

  final String code;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            code,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (status case final status?) Chip(label: Text(status)),
      ],
    );
  }
}

class _CachedBox extends StatelessWidget {
  const _CachedBox({
    required this.box,
    required this.productName,
    required this.onOpen,
  });

  final BoxRow box;
  final String? productName;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Headline(
          code: box.code,
          status: boxStatusLabel(context.l10n, box.status),
        ),
        const SizedBox(height: 8),
        if (productName case final name?)
          Text(name, style: theme.textTheme.titleMedium),
        Text(
          [
            '${box.quantity} ${box.unit}',
            if (box.batch case final batch?) 'lote $batch',
            if (box.expiryDate case final expiry?)
              'vence ${formatShortDate(expiry)}',
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ConfirmButton(
            label: context.l10n.scanningAbrirFicha,
            onPressed: onOpen,
          ),
        ),
      ],
    );
  }
}

/// La ficha pública trae menos que el registro del operador, y quien la lee
/// tiene que saberlo: la diferencia entre «esto es todo lo que hay» y «esto es
/// lo que se pudo consultar» cambia lo que alguien decide con ella delante.
class _PublicBox extends StatelessWidget {
  const _PublicBox({required this.box});

  final BoxPublicOut box;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Headline(
          code: box.code,
          status: boxStatusLabel(context.l10n, box.status),
        ),
        const SizedBox(height: 8),
        Text(box.displayName, style: theme.textTheme.titleMedium),
        Text(
          [
            '${box.quantity} ${box.unit}',
            categoryLabel(box.category),
            if (box.expiryDate case final expiry?)
              'vence ${formatShortDate(expiry)}',
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        const _Notice(
          'Esta caja no está descargada en el dispositivo. Se muestra su ficha '
          'pública, que trae menos datos que el registro del centro.',
        ),
      ],
    );
  }
}

class _Pallet extends StatelessWidget {
  const _Pallet({required this.pallet});

  final PalletPublicOut pallet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Headline(
          code: pallet.code,
          status: palletStatusLabel(context.l10n, pallet.status),
        ),
        const SizedBox(height: 8),
        Text(pallet.centerName, style: theme.textTheme.titleMedium),
        Text(
          [
            '${pallet.boxCount} ${pallet.boxCount == 1 ? 'caja' : 'cajas'}',
            if (pallet.closedAt case final closed?)
              'cerrada ${formatShortDate(closed)}',
            if (pallet.deliveredAt case final delivered?)
              'entregada ${formatShortDate(delivered)}',
          ].join(' · '),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Donation extends StatelessWidget {
  const _Donation({required this.donation, required this.onOpen});

  final DonationOut donation;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = donation.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Headline(
          code: donation.code,
          status: donationStatusLabel(context.l10n, donation.status),
        ),
        const SizedBox(height: 8),
        Text(
          'Registrada el ${formatShortDate(donation.createdAt)}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final item in items.take(4))
          Text(
            '· ${item.freeText ?? 'Artículo'} — ${item.quantity} ${item.unit}',
            style: theme.textTheme.bodySmall,
          ),
        if (items.length > 4)
          Text('y ${items.length - 4} más', style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        const _Notice(
          'Lo que se registra es lo que llegó. Los artículos de arriba son lo '
          'que declaró quien donó, y no se convierten en cajas solos.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ConfirmButton(
            label: context.l10n.scanningCapturarEstaDonacion,
            onPressed: onOpen,
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
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
  const _Message({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(text, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}
