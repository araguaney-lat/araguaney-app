import '../i18n/generated/app_localizations.dart';

/// The eight categories of `PRODUCT_CATEGORIES` in the backend, in their
/// order.
///
/// The list is here and not in the form that offers it because it is the
/// server's vocabulary, not one screen's: the same eight keys name a category
/// on a record, in a filter and in a dropdown. A ninth one added by the backend
/// still renders wherever it is read — see [categoryLabel] — but it cannot be
/// **chosen** until this list learns it, which is the honest trade: offering a
/// key this build has never seen would be guessing.
const productCategories = [
  'MEDICINE',
  'MEDICAL_SUPPLY',
  'FOOD',
  'WATER',
  'HYGIENE',
  'TOOL',
  'RESCUE_GEAR',
  'OTHER',
];

/// How a catalogue category reads.
///
/// The eight keys are those of `PRODUCT_CATEGORIES` in the backend. One this
/// version does not know is drawn as it is: the catalogue can grow, and an old
/// binary cannot make a whole row disappear for failing to recognise its name.
///
/// It lives in `core` and not inside a screen because the category is shown in
/// several, and a translation table that only one of them imports ends up
/// leaving the rest showing the server's key. That is exactly what happened:
/// the product picker spent months showing `MEDICAL_SUPPLY`.
String categoryLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'MEDICINE' => l10n.categoryMedicine,
      'MEDICAL_SUPPLY' => l10n.categoryMedicalSupply,
      'FOOD' => l10n.categoryFood,
      'WATER' => l10n.categoryWater,
      'HYGIENE' => l10n.categoryHygiene,
      'TOOL' => l10n.categoryTool,
      'RESCUE_GEAR' => l10n.categoryRescueGear,
      'OTHER' => l10n.categoryOther,
      _ => category,
    };
