import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import 'donations_repository.dart';

final donationsRepositoryProvider = Provider<DonationsRepository>(
  (ref) => DonationsRepository(ref.watch(restClientProvider).donations),
);

/// Las que vienen en camino a este centro, y las que ya se recibieron.
///
/// Son dos preguntas distintas y el servidor las separa con un parámetro, así
/// que aquí son dos providers y no una lista filtrada: pedir las recibidas para
/// tirar la mitad sería traer meses de historial por una pestaña.
final incomingDonationsProvider =
    FutureProvider<DonationsOutcome<List<DonationOut>>>(
      (ref) => ref.watch(donationsRepositoryProvider).list(incoming: true),
    );

final receivedDonationsProvider =
    FutureProvider<DonationsOutcome<List<DonationOut>>>(
      (ref) => ref.watch(donationsRepositoryProvider).list(incoming: false),
    );

/// La ficha de una donación por su código.
final donationRecordProvider =
    FutureProvider.family<DonationsOutcome<DonationOut>, String>(
      (ref, code) => ref.watch(donationsRepositoryProvider).byCode(code),
    );

/// Qué producto del catálogo se parece a lo que el donante escribió.
typedef SuggestionQuery = ({String code, String text});

final catalogSuggestionsProvider =
    FutureProvider.family<List<ProductTypeOut>, SuggestionQuery>((
      ref,
      query,
    ) async {
      final outcome = await ref
          .watch(donationsRepositoryProvider)
          .suggestions(code: query.code, text: query.text);
      // Un fallo se trata como «no hay sugerencias»: esto ayuda a no teclear,
      // y una fila roja porque el proveedor no respondió sería ruido sobre una
      // pantalla donde hay gente esperando con cajas.
      return switch (outcome) {
        DonationsRead(:final value) => value,
        DonationsRefused() => const [],
      };
    });

/// El enlace firmado de una foto, pedido al mirarla porque caduca.
typedef PhotoQuery = ({String code, String photoId});

final donationPhotoUrlProvider =
    FutureProvider.family<DonationsOutcome<String>, PhotoQuery>(
      (ref, query) => ref
          .watch(donationsRepositoryProvider)
          .photoUrl(code: query.code, photoId: query.photoId),
    );
