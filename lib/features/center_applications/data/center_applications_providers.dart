import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/generated/models/center_application_out.dart';
import '../../../core/auth/auth_providers.dart';
import 'center_applications_repository.dart';

final centerApplicationsRepositoryProvider =
    Provider<CenterApplicationsRepository>(
      (ref) => CenterApplicationsRepository(
        ref.watch(restClientProvider).centerApplications,
      ),
    );

/// Lo que espera una decisión.
final applicationQueueProvider =
    FutureProvider<ApplicationsOutcome<List<CenterApplicationOut>>>(
      (ref) => ref.watch(centerApplicationsRepositoryProvider).queue(),
    );

/// Si esta sesión puede revisar postulaciones.
///
/// El backend acepta a una administración nacional —acotada a su país— o a una
/// superadministración, que las ve todas. Desde el cliente las dos se ven igual
/// a través de `center_role`, así que esto solo evita ofrecer una pantalla que
/// va a responder 403; quién ve qué lo sigue decidiendo el servidor.
final canReviewApplicationsProvider = Provider<bool>(
  (ref) => ref.watch(isNationalAdminProvider),
);
