import 'package:araguaney_app/core/ui/relative_time.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/l10n.dart';

void main() {
  final now = DateTime.utc(2026, 8, 10, 12);

  Future<String> ageOf(Duration elapsed) async =>
      describeAge(await spanish(), now.subtract(elapsed), now);

  test('under a minute reads as a moment, not as a number', () async {
    expect(await ageOf(const Duration(seconds: 40)), 'hace un momento');
  });

  test('minutes and hours are pluralised', () async {
    expect(await ageOf(const Duration(minutes: 1)), 'hace 1 minuto');
    expect(await ageOf(const Duration(minutes: 12)), 'hace 12 minutos');
    expect(await ageOf(const Duration(hours: 1)), 'hace 1 hora');
    expect(await ageOf(const Duration(hours: 5)), 'hace 5 horas');
  });

  test('past a day the scale changes to days', () async {
    expect(await ageOf(const Duration(days: 1)), 'hace 1 día');
    expect(await ageOf(const Duration(days: 3)), 'hace 3 días');
  });

  test('the boundaries do not skip a scale', () async {
    expect(await ageOf(const Duration(seconds: 60)), 'hace 1 minuto');
    expect(await ageOf(const Duration(minutes: 60)), 'hace 1 hora');
    expect(await ageOf(const Duration(hours: 24)), 'hace 1 día');
  });
}
