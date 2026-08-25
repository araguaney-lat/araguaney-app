import 'package:araguaney_app/core/api/export_job.dart';
import 'package:araguaney_app/core/api/generated/clients/exports_api.dart';
import 'package:araguaney_app/core/api/generated/clients/shipments_api.dart';
import 'package:araguaney_app/core/api/generated/models/qr_event_out.dart';
import 'package:araguaney_app/core/ui/status_labels.dart';
import 'package:araguaney_app/features/shipments/data/shipments_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_api.dart';
import '../../support/fake_http_adapter.dart';
import '../../support/fixtures.dart';
import '../../support/l10n.dart';

void main() {
  ShipmentsRepository repositoryOn(FakeHttpAdapter adapter) {
    final dio = fakeDio(adapter);
    return ShipmentsRepository(
      shipments: ShipmentsApi(dio),
      exports: ExportsApi(dio),
    );
  }

  /// No espera de verdad: el sondeo se mide en peticiones, no en segundos.
  Future<void> noWait(Duration _) async {}

  group('asking for the manifest', () {
    test('a job that finishes brings back its link', () async {
      var calls = 0;
      final adapter = FakeHttpAdapter((options) {
        calls++;
        return FakeResponse(
          options.path.contains('manifest') ? 202 : 200,
          calls == 1
              ? exportJobJson(status: 'PENDING')
              : exportJobJson(
                  status: 'DONE',
                  downloadUrl: 'https://files.test/manifiesto.pdf',
                ),
        );
      });

      final outcome = await repositoryOn(
        adapter,
      ).manifest('shipment-1', wait: noWait);

      expect(
        (outcome as DocumentReady).downloadUrl,
        'https://files.test/manifiesto.pdf',
      );
    });

    test('a job that is already done is not polled again', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(
          202,
          exportJobJson(
            status: 'DONE',
            downloadUrl: 'https://files.test/m.pdf',
          ),
        ),
      );

      await repositoryOn(adapter).manifest('shipment-1', wait: noWait);

      expect(adapter.requests, hasLength(1));
    });

    test('a failed job says what the server said', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(
          202,
          exportJobJson(status: 'FAILED', error: 'El envío no tiene tarimas'),
        ),
      );

      final outcome = await repositoryOn(
        adapter,
      ).manifest('shipment-1', wait: noWait);

      // El trabajo terminó en error y el servidor dijo por qué: sus palabras
      // viajan tal cual, como cualquier rechazo de regla de negocio.
      expect(
        (outcome as DocumentFailed).serverError,
        'El envío no tiene tarimas',
      );
    });

    test(
      'a job that never finishes stops instead of spinning forever',
      () async {
        // Dejar a alguien mirando una rueda es peor que decirle que vuelva a
        // intentarlo: el trabajo sigue vivo en el servidor.
        final adapter = FakeHttpAdapter(
          (_) => FakeResponse(202, exportJobJson(status: 'RUNNING')),
        );

        final outcome = await repositoryOn(
          adapter,
        ).manifest('shipment-1', wait: noWait);

        expect(outcome, isA<DocumentStillWorking>());
        expect(adapter.requests.length, lessThan(20));
      },
    );

    test('done without a link is a failure, not a silent nothing', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeResponse(202, exportJobJson(status: 'DONE')),
      );

      final outcome = await repositoryOn(
        adapter,
      ).manifest('shipment-1', wait: noWait);

      expect(outcome, isA<DocumentFailed>());
    });

    test('no signal is reported as a failure with its reason', () async {
      final outcome = await repositoryOn(
        OfflineHttpAdapter(),
      ).manifest('shipment-1', wait: noWait);

      expect(
        (outcome as DocumentFailed).failure!.operatorMessage(await spanish()),
        contains('No hay conexión'),
      );
    });
  });

  group('reading the journey', () {
    test('a milestone reads by its name', () async {
      final l10n = await spanish();
      final described = describeEvent(
        l10n,
        QrEventOut(
          fromStatus: 'SHIPPED',
          toStatus: 'SHIPPED',
          milestone: 'CUSTOMS_CLEARED',
          note: 'Sin inspección',
          ts: testNow,
        ),
        statusLabel: (status) => shipmentStatusLabel(l10n, status),
      );

      expect(described.title, 'Liberado de aduana');
      expect(described.note, 'Sin inspección');
    });

    test('a state change reads in the language it is operated in', () async {
      final l10n = await spanish();
      // Este test fijaba «CLOSED → IN_TRANSIT», que estaba mal dos veces: la
      // clave cruda no es lo que una persona debe leer, y `IN_TRANSIT` no es
      // un estado de envio sino de transferencia —`SHIPMENT_STATUSES` es
      // OPEN, CLOSED, SHIPPED, DELIVERED, RECONCILED. Traducir las etiquetas
      // fue lo que destapo el fixture inventado.
      final described = describeEvent(
        l10n,
        QrEventOut(
          fromStatus: 'CLOSED',
          toStatus: 'SHIPPED',
          note: null,
          ts: testNow,
        ),
        statusLabel: (status) => shipmentStatusLabel(l10n, status),
      );

      expect(described.title, 'Cerrado → Despachado');
    });

    test('a milestone this version does not know still reads', () async {
      final l10n = await spanish();
      // El vocabulario del backend puede crecer, y un envío no puede perder un
      // paso de su recorrido porque el teléfono sea viejo.
      expect(milestoneLabel(l10n, 'LOADED_ON_SHIP'), 'LOADED_ON_SHIP');
    });
  });
}
