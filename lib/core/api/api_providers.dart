import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'generated/rest_client.dart';

/// The generated client on top of the `Dio` that carries the session.
///
/// It is the features' only entry point to the API: nobody builds their own
/// client or writes routes by hand.
final restClientProvider = Provider<RestClient>(
  (ref) => RestClient(ref.watch(apiDioProvider)),
);
