import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/db/db_providers.dart';
import 'scan_resolver.dart';

final scanResolverProvider = Provider<ScanResolver>((ref) {
  final client = ref.watch(restClientProvider);
  return ScanResolver(
    boxes: client.boxes,
    pallets: client.pallets,
    donations: client.donations,
    database: ref.watch(appDatabaseProvider),
  );
});
