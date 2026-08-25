import '../i18n/generated/app_localizations.dart';

/// Las ocho categorías de `PRODUCT_CATEGORIES` en el backend, en su orden.
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

/// Cómo se lee una categoría del catálogo.
///
/// Las ocho claves son las de `PRODUCT_CATEGORIES` en el backend. Una que esta
/// versión no conozca se dibuja tal cual: el catálogo puede crecer y un binario
/// viejo no puede hacer desaparecer una fila entera por no reconocer su nombre.
///
/// Vive en `core` y no dentro de una pantalla porque la categoría se enseña en
/// varias, y una tabla de traducción que solo importa una acaba dejando a las
/// demás enseñando la clave del servidor. Fue exactamente lo que pasó: el
/// selector de producto llevaba meses mostrando `MEDICAL_SUPPLY`.
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
