import '../i18n/generated/app_localizations.dart';

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
      'MEDICINE' => 'Medicamentos',
      'MEDICAL_SUPPLY' => l10n.categoryMedicalSupply,
      'FOOD' => 'Alimentos',
      'WATER' => 'Agua',
      'HYGIENE' => 'Higiene',
      'TOOL' => 'Herramientas',
      'RESCUE_GEAR' => l10n.categoryRescueGear,
      'OTHER' => 'Otros',
      _ => category,
    };
