import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/donation_out.dart';
import '../../../core/api/generated/models/product_type_out.dart';
import 'donations_repository.dart';

final donationsRepositoryProvider = Provider<DonationsRepository>(
  (ref) => DonationsRepository(ref.watch(restClientProvider).donations),
);

/// The ones on their way to this centre, and the ones already received.
///
/// They are two different questions and the server separates them with a
/// parameter, so here they are two providers and not one filtered list: asking
/// for the received ones to throw half away would bring months of history for
/// the sake of a tab.
final incomingDonationsProvider =
    FutureProvider<DonationsOutcome<List<DonationOut>>>(
      (ref) => ref.watch(donationsRepositoryProvider).list(incoming: true),
    );

final receivedDonationsProvider =
    FutureProvider<DonationsOutcome<List<DonationOut>>>(
      (ref) => ref.watch(donationsRepositoryProvider).list(incoming: false),
    );

/// A donation's record by its code.
final donationRecordProvider =
    FutureProvider.family<DonationsOutcome<DonationOut>, String>(
      (ref, code) => ref.watch(donationsRepositoryProvider).byCode(code),
    );

/// Which catalogue product resembles what the donor wrote.
typedef SuggestionQuery = ({String code, String text});

final catalogSuggestionsProvider =
    FutureProvider.family<List<ProductTypeOut>, SuggestionQuery>((
      ref,
      query,
    ) async {
      final outcome = await ref
          .watch(donationsRepositoryProvider)
          .suggestions(code: query.code, text: query.text);
      // A failure is treated as «no suggestions»: this is here to save typing,
      // and a red row because the provider did not answer would be noise on a
      // screen where people are waiting with boxes.
      return switch (outcome) {
        DonationsRead(:final value) => value,
        DonationsRefused() => const [],
      };
    });

/// A photo's signed link, asked for when it is looked at because it expires.
typedef PhotoQuery = ({String code, String photoId});

final donationPhotoUrlProvider =
    FutureProvider.family<DonationsOutcome<String>, PhotoQuery>(
      (ref, query) => ref
          .watch(donationsRepositoryProvider)
          .photoUrl(code: query.code, photoId: query.photoId),
    );
