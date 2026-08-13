import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/qr_event_out.dart';
import 'shipments_repository.dart';

final shipmentsRepositoryProvider = Provider<ShipmentsRepository>((ref) {
  final client = ref.watch(restClientProvider);
  return ShipmentsRepository(
    shipments: client.shipments,
    exports: client.exports,
  );
});

/// El recorrido del envío: cambios de estado y hitos logísticos.
final shipmentEventsProvider = FutureProvider.family<List<QrEventOut>, String>(
  (ref, shipmentId) =>
      ref.watch(shipmentsRepositoryProvider).events(shipmentId),
);

/// Abrir un enlace fuera de la aplicación.
///
/// Se expone como función para que una prueba pueda comprobar que el manifiesto
/// se abre sin lanzar un navegador de verdad. Devuelve si se pudo.
typedef OpenLink = Future<bool> Function(String url);

final openLinkProvider = Provider<OpenLink>(
  (ref) => (url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    // El manifiesto es un PDF firmado: lo abre el visor del sistema, que es
    // donde se puede guardar, imprimir o mandar por donde haga falta.
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  },
);
