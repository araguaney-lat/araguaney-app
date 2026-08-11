import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'generated/rest_client.dart';

/// Cliente generado sobre el `Dio` con sesión.
///
/// Es el único punto de entrada a la API para las features: nadie construye su
/// propio cliente ni escribe rutas a mano.
final restClientProvider = Provider<RestClient>(
  (ref) => RestClient(ref.watch(apiDioProvider)),
);
