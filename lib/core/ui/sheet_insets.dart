import 'package:flutter/material.dart';

/// How much room has to be left free below a bottom sheet's content.
///
/// There are **two** obstacles and they have to be added up, not chosen
/// between:
///
/// - The keyboard, when it is open (`viewInsets`).
/// - The system navigation bar (`padding`), which on a three-button phone takes
///   a tall strip and with gesture navigation takes almost nothing. An emulator
///   set up with gestures does not show this problem: the button looks perfect
///   there and ends up half covered on the phone next to it.
///
/// Adding `padding` and not `viewPadding` is what avoids counting it twice:
/// when the keyboard is open, `padding.bottom` is zero because the keyboard
/// already covers the bar, and what is left is the keyboard's height.
///
/// It exists as a function and not as a line copied into every sheet because it
/// was copied into six, all of them adding the keyboard alone.
///
/// `showModalBottomSheet(useSafeArea: true)` does **not** solve this: it
/// protects the top edge and leaves the bottom one to the sheet.
///
/// On a full screen it is not needed: there `SafeArea` does move the system bar
/// out of the way, and the only thing to add is the keyboard. This function is
/// for the sheets, which is where `SafeArea` does not reach.
double sheetBottomInset(BuildContext context, {double base = 16}) =>
    base +
    MediaQuery.paddingOf(context).bottom +
    MediaQuery.viewInsetsOf(context).bottom;
