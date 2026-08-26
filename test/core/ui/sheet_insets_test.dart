import 'package:araguaney_app/core/ui/sheet_insets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<double> measure(
    WidgetTester tester, {
    required double systemBar,
    required double keyboard,
  }) async {
    late double result;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          // `padding` is what is left of the system inset after the keyboard:
          // it is zero while the keyboard is open, because the keyboard already
          // covers the bar.
          padding: EdgeInsets.only(bottom: keyboard > 0 ? 0 : systemBar),
          viewPadding: EdgeInsets.only(bottom: systemBar),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: Builder(
          builder: (context) {
            result = sheetBottomInset(context, base: 16);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('with three-button navigation it clears the system bar', (
    tester,
  ) async {
    // It is the case an emulator with gestures does not show: there the bar is
    // barely anything and the button looks well placed.
    expect(await measure(tester, systemBar: 48, keyboard: 0), 64);
  });

  testWidgets('with gesture navigation it barely adds anything', (
    tester,
  ) async {
    expect(await measure(tester, systemBar: 16, keyboard: 0), 32);
  });

  testWidgets('with the keyboard open it clears the keyboard, once', (
    tester,
  ) async {
    // The two are not added: the keyboard is drawn over the bar, so counting
    // both would leave a gap the size of the bar under the keyboard.
    expect(await measure(tester, systemBar: 48, keyboard: 300), 316);
  });
}
