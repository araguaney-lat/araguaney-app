import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/intake_out.dart';
import '../../catalog/data/catalog_providers.dart';
import '../../intake/data/intake_providers.dart';
import '../../pallets/data/pallets_providers.dart';
import '../../risk_reviews/data/risk_reviews_providers.dart';

/// Revisiones que esperan una decisión.
///
/// El servidor devuelve las del centro; aquí solo se cuentan las que siguen
/// pendientes, porque una resuelta ya no le pide nada a nadie.
final pendingReviewCountProvider = Provider<int>((ref) {
  final reviews = ref.watch(riskReviewsProvider).valueOrNull ?? const [];
  return reviews.where((review) => review.status == 'PENDING').length;
});

/// Tarimas abiertas: las que todavía admiten cajas.
final openPalletCountProvider = Provider<int>((ref) {
  final pallets = ref.watch(palletsProvider).valueOrNull ?? const [];
  return pallets.where((pallet) => pallet.closedAt == null).length;
});

/// Capturas registradas hoy en el centro.
///
/// Se filtra por fecha local y no por la del servidor: quien pregunta «cuántas
/// van hoy» piensa en su jornada, que empieza cuando amanece donde está.
final todaysIntakeCountProvider = Provider<int>((ref) {
  final intakes = ref.watch(intakesProvider).valueOrNull ?? const <IntakeOut>[];
  final now = DateTime.now();
  return intakes.where((intake) {
    final at = intake.createdAt.toLocal();
    return at.year == now.year && at.month == now.month && at.day == now.day;
  }).length;
});

/// Cuánto se puede trabajar sin señal ahora mismo.
///
/// Las dos cifras que deciden si una jornada sin conexión es posible: el
/// catálogo que se puede consultar y los códigos de caja reservados que se
/// pueden gastar. Cero códigos con cero señal significa no poder sellar nada.
final offlineReadinessProvider = Provider<({int products, int codes})>((ref) {
  // Sin categoría: el catálogo entero, que es lo que se descargó.
  final products =
      ref.watch(productTypesProvider(null)).valueOrNull?.length ?? 0;
  final codes = ref.watch(availableBoxCodesProvider).valueOrNull ?? 0;
  return (products: products, codes: codes);
});
