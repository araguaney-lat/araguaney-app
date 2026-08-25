// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductTypesTable extends ProductTypes
    with TableInfo<$ProductTypesTable, ProductTypeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formMeta = const VerificationMeta('form');
  @override
  late final GeneratedColumn<String> form = GeneratedColumn<String>(
    'form',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  @override
  late final GeneratedColumn<String> strength = GeneratedColumn<String>(
    'strength',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultUnitMeta = const VerificationMeta(
    'defaultUnit',
  );
  @override
  late final GeneratedColumn<String> defaultUnit = GeneratedColumn<String>(
    'default_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gtinMeta = const VerificationMeta('gtin');
  @override
  late final GeneratedColumn<String> gtin = GeneratedColumn<String>(
    'gtin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _innNameMeta = const VerificationMeta(
    'innName',
  );
  @override
  late final GeneratedColumn<String> innName = GeneratedColumn<String>(
    'inn_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isControlledMeta = const VerificationMeta(
    'isControlled',
  );
  @override
  late final GeneratedColumn<bool> isControlled = GeneratedColumn<bool>(
    'is_controlled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_controlled" IN (0, 1))',
    ),
  );
  static const VerificationMeta _minShelfLifeDaysMeta = const VerificationMeta(
    'minShelfLifeDays',
  );
  @override
  late final GeneratedColumn<int> minShelfLifeDays = GeneratedColumn<int>(
    'min_shelf_life_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitWeightKgMeta = const VerificationMeta(
    'unitWeightKg',
  );
  @override
  late final GeneratedColumn<String> unitWeightKg = GeneratedColumn<String>(
    'unit_weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unspscCodeMeta = const VerificationMeta(
    'unspscCode',
  );
  @override
  late final GeneratedColumn<String> unspscCode = GeneratedColumn<String>(
    'unspsc_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _campaignIdMeta = const VerificationMeta(
    'campaignId',
  );
  @override
  late final GeneratedColumn<String> campaignId = GeneratedColumn<String>(
    'campaign_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    category,
    brand,
    form,
    strength,
    defaultUnit,
    gtin,
    innName,
    isControlled,
    minShelfLifeDays,
    unitWeightKg,
    unspscCode,
    campaignId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductTypeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('form')) {
      context.handle(
        _formMeta,
        form.isAcceptableOrUnknown(data['form']!, _formMeta),
      );
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    }
    if (data.containsKey('default_unit')) {
      context.handle(
        _defaultUnitMeta,
        defaultUnit.isAcceptableOrUnknown(
          data['default_unit']!,
          _defaultUnitMeta,
        ),
      );
    }
    if (data.containsKey('gtin')) {
      context.handle(
        _gtinMeta,
        gtin.isAcceptableOrUnknown(data['gtin']!, _gtinMeta),
      );
    }
    if (data.containsKey('inn_name')) {
      context.handle(
        _innNameMeta,
        innName.isAcceptableOrUnknown(data['inn_name']!, _innNameMeta),
      );
    }
    if (data.containsKey('is_controlled')) {
      context.handle(
        _isControlledMeta,
        isControlled.isAcceptableOrUnknown(
          data['is_controlled']!,
          _isControlledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isControlledMeta);
    }
    if (data.containsKey('min_shelf_life_days')) {
      context.handle(
        _minShelfLifeDaysMeta,
        minShelfLifeDays.isAcceptableOrUnknown(
          data['min_shelf_life_days']!,
          _minShelfLifeDaysMeta,
        ),
      );
    }
    if (data.containsKey('unit_weight_kg')) {
      context.handle(
        _unitWeightKgMeta,
        unitWeightKg.isAcceptableOrUnknown(
          data['unit_weight_kg']!,
          _unitWeightKgMeta,
        ),
      );
    }
    if (data.containsKey('unspsc_code')) {
      context.handle(
        _unspscCodeMeta,
        unspscCode.isAcceptableOrUnknown(data['unspsc_code']!, _unspscCodeMeta),
      );
    }
    if (data.containsKey('campaign_id')) {
      context.handle(
        _campaignIdMeta,
        campaignId.isAcceptableOrUnknown(data['campaign_id']!, _campaignIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductTypeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductTypeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      form: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form'],
      ),
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strength'],
      ),
      defaultUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_unit'],
      ),
      gtin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gtin'],
      ),
      innName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inn_name'],
      ),
      isControlled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_controlled'],
      )!,
      minShelfLifeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_shelf_life_days'],
      ),
      unitWeightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_weight_kg'],
      ),
      unspscCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unspsc_code'],
      ),
      campaignId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}campaign_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProductTypesTable createAlias(String alias) {
    return $ProductTypesTable(attachedDatabase, alias);
  }
}

class ProductTypeRow extends DataClass implements Insertable<ProductTypeRow> {
  final String id;
  final String displayName;
  final String category;
  final String? brand;
  final String? form;
  final String? strength;
  final String? defaultUnit;
  final String? gtin;
  final String? innName;
  final bool isControlled;
  final int? minShelfLifeDays;

  /// Decimal del servidor. Se guarda como texto para no perder precisión al
  /// pasar por un `double`.
  final String? unitWeightKg;
  final String? unspscCode;

  /// Campaña que restringe la visibilidad del producto, o nulo si es general.
  final String? campaignId;
  final DateTime createdAt;
  const ProductTypeRow({
    required this.id,
    required this.displayName,
    required this.category,
    this.brand,
    this.form,
    this.strength,
    this.defaultUnit,
    this.gtin,
    this.innName,
    required this.isControlled,
    this.minShelfLifeDays,
    this.unitWeightKg,
    this.unspscCode,
    this.campaignId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || form != null) {
      map['form'] = Variable<String>(form);
    }
    if (!nullToAbsent || strength != null) {
      map['strength'] = Variable<String>(strength);
    }
    if (!nullToAbsent || defaultUnit != null) {
      map['default_unit'] = Variable<String>(defaultUnit);
    }
    if (!nullToAbsent || gtin != null) {
      map['gtin'] = Variable<String>(gtin);
    }
    if (!nullToAbsent || innName != null) {
      map['inn_name'] = Variable<String>(innName);
    }
    map['is_controlled'] = Variable<bool>(isControlled);
    if (!nullToAbsent || minShelfLifeDays != null) {
      map['min_shelf_life_days'] = Variable<int>(minShelfLifeDays);
    }
    if (!nullToAbsent || unitWeightKg != null) {
      map['unit_weight_kg'] = Variable<String>(unitWeightKg);
    }
    if (!nullToAbsent || unspscCode != null) {
      map['unspsc_code'] = Variable<String>(unspscCode);
    }
    if (!nullToAbsent || campaignId != null) {
      map['campaign_id'] = Variable<String>(campaignId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProductTypesCompanion toCompanion(bool nullToAbsent) {
    return ProductTypesCompanion(
      id: Value(id),
      displayName: Value(displayName),
      category: Value(category),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      form: form == null && nullToAbsent ? const Value.absent() : Value(form),
      strength: strength == null && nullToAbsent
          ? const Value.absent()
          : Value(strength),
      defaultUnit: defaultUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultUnit),
      gtin: gtin == null && nullToAbsent ? const Value.absent() : Value(gtin),
      innName: innName == null && nullToAbsent
          ? const Value.absent()
          : Value(innName),
      isControlled: Value(isControlled),
      minShelfLifeDays: minShelfLifeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(minShelfLifeDays),
      unitWeightKg: unitWeightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(unitWeightKg),
      unspscCode: unspscCode == null && nullToAbsent
          ? const Value.absent()
          : Value(unspscCode),
      campaignId: campaignId == null && nullToAbsent
          ? const Value.absent()
          : Value(campaignId),
      createdAt: Value(createdAt),
    );
  }

  factory ProductTypeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductTypeRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      category: serializer.fromJson<String>(json['category']),
      brand: serializer.fromJson<String?>(json['brand']),
      form: serializer.fromJson<String?>(json['form']),
      strength: serializer.fromJson<String?>(json['strength']),
      defaultUnit: serializer.fromJson<String?>(json['defaultUnit']),
      gtin: serializer.fromJson<String?>(json['gtin']),
      innName: serializer.fromJson<String?>(json['innName']),
      isControlled: serializer.fromJson<bool>(json['isControlled']),
      minShelfLifeDays: serializer.fromJson<int?>(json['minShelfLifeDays']),
      unitWeightKg: serializer.fromJson<String?>(json['unitWeightKg']),
      unspscCode: serializer.fromJson<String?>(json['unspscCode']),
      campaignId: serializer.fromJson<String?>(json['campaignId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'category': serializer.toJson<String>(category),
      'brand': serializer.toJson<String?>(brand),
      'form': serializer.toJson<String?>(form),
      'strength': serializer.toJson<String?>(strength),
      'defaultUnit': serializer.toJson<String?>(defaultUnit),
      'gtin': serializer.toJson<String?>(gtin),
      'innName': serializer.toJson<String?>(innName),
      'isControlled': serializer.toJson<bool>(isControlled),
      'minShelfLifeDays': serializer.toJson<int?>(minShelfLifeDays),
      'unitWeightKg': serializer.toJson<String?>(unitWeightKg),
      'unspscCode': serializer.toJson<String?>(unspscCode),
      'campaignId': serializer.toJson<String?>(campaignId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProductTypeRow copyWith({
    String? id,
    String? displayName,
    String? category,
    Value<String?> brand = const Value.absent(),
    Value<String?> form = const Value.absent(),
    Value<String?> strength = const Value.absent(),
    Value<String?> defaultUnit = const Value.absent(),
    Value<String?> gtin = const Value.absent(),
    Value<String?> innName = const Value.absent(),
    bool? isControlled,
    Value<int?> minShelfLifeDays = const Value.absent(),
    Value<String?> unitWeightKg = const Value.absent(),
    Value<String?> unspscCode = const Value.absent(),
    Value<String?> campaignId = const Value.absent(),
    DateTime? createdAt,
  }) => ProductTypeRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    category: category ?? this.category,
    brand: brand.present ? brand.value : this.brand,
    form: form.present ? form.value : this.form,
    strength: strength.present ? strength.value : this.strength,
    defaultUnit: defaultUnit.present ? defaultUnit.value : this.defaultUnit,
    gtin: gtin.present ? gtin.value : this.gtin,
    innName: innName.present ? innName.value : this.innName,
    isControlled: isControlled ?? this.isControlled,
    minShelfLifeDays: minShelfLifeDays.present
        ? minShelfLifeDays.value
        : this.minShelfLifeDays,
    unitWeightKg: unitWeightKg.present ? unitWeightKg.value : this.unitWeightKg,
    unspscCode: unspscCode.present ? unspscCode.value : this.unspscCode,
    campaignId: campaignId.present ? campaignId.value : this.campaignId,
    createdAt: createdAt ?? this.createdAt,
  );
  ProductTypeRow copyWithCompanion(ProductTypesCompanion data) {
    return ProductTypeRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      category: data.category.present ? data.category.value : this.category,
      brand: data.brand.present ? data.brand.value : this.brand,
      form: data.form.present ? data.form.value : this.form,
      strength: data.strength.present ? data.strength.value : this.strength,
      defaultUnit: data.defaultUnit.present
          ? data.defaultUnit.value
          : this.defaultUnit,
      gtin: data.gtin.present ? data.gtin.value : this.gtin,
      innName: data.innName.present ? data.innName.value : this.innName,
      isControlled: data.isControlled.present
          ? data.isControlled.value
          : this.isControlled,
      minShelfLifeDays: data.minShelfLifeDays.present
          ? data.minShelfLifeDays.value
          : this.minShelfLifeDays,
      unitWeightKg: data.unitWeightKg.present
          ? data.unitWeightKg.value
          : this.unitWeightKg,
      unspscCode: data.unspscCode.present
          ? data.unspscCode.value
          : this.unspscCode,
      campaignId: data.campaignId.present
          ? data.campaignId.value
          : this.campaignId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductTypeRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('form: $form, ')
          ..write('strength: $strength, ')
          ..write('defaultUnit: $defaultUnit, ')
          ..write('gtin: $gtin, ')
          ..write('innName: $innName, ')
          ..write('isControlled: $isControlled, ')
          ..write('minShelfLifeDays: $minShelfLifeDays, ')
          ..write('unitWeightKg: $unitWeightKg, ')
          ..write('unspscCode: $unspscCode, ')
          ..write('campaignId: $campaignId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    category,
    brand,
    form,
    strength,
    defaultUnit,
    gtin,
    innName,
    isControlled,
    minShelfLifeDays,
    unitWeightKg,
    unspscCode,
    campaignId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductTypeRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.category == this.category &&
          other.brand == this.brand &&
          other.form == this.form &&
          other.strength == this.strength &&
          other.defaultUnit == this.defaultUnit &&
          other.gtin == this.gtin &&
          other.innName == this.innName &&
          other.isControlled == this.isControlled &&
          other.minShelfLifeDays == this.minShelfLifeDays &&
          other.unitWeightKg == this.unitWeightKg &&
          other.unspscCode == this.unspscCode &&
          other.campaignId == this.campaignId &&
          other.createdAt == this.createdAt);
}

class ProductTypesCompanion extends UpdateCompanion<ProductTypeRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<String> category;
  final Value<String?> brand;
  final Value<String?> form;
  final Value<String?> strength;
  final Value<String?> defaultUnit;
  final Value<String?> gtin;
  final Value<String?> innName;
  final Value<bool> isControlled;
  final Value<int?> minShelfLifeDays;
  final Value<String?> unitWeightKg;
  final Value<String?> unspscCode;
  final Value<String?> campaignId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ProductTypesCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.category = const Value.absent(),
    this.brand = const Value.absent(),
    this.form = const Value.absent(),
    this.strength = const Value.absent(),
    this.defaultUnit = const Value.absent(),
    this.gtin = const Value.absent(),
    this.innName = const Value.absent(),
    this.isControlled = const Value.absent(),
    this.minShelfLifeDays = const Value.absent(),
    this.unitWeightKg = const Value.absent(),
    this.unspscCode = const Value.absent(),
    this.campaignId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductTypesCompanion.insert({
    required String id,
    required String displayName,
    required String category,
    this.brand = const Value.absent(),
    this.form = const Value.absent(),
    this.strength = const Value.absent(),
    this.defaultUnit = const Value.absent(),
    this.gtin = const Value.absent(),
    this.innName = const Value.absent(),
    required bool isControlled,
    this.minShelfLifeDays = const Value.absent(),
    this.unitWeightKg = const Value.absent(),
    this.unspscCode = const Value.absent(),
    this.campaignId = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       category = Value(category),
       isControlled = Value(isControlled),
       createdAt = Value(createdAt);
  static Insertable<ProductTypeRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<String>? category,
    Expression<String>? brand,
    Expression<String>? form,
    Expression<String>? strength,
    Expression<String>? defaultUnit,
    Expression<String>? gtin,
    Expression<String>? innName,
    Expression<bool>? isControlled,
    Expression<int>? minShelfLifeDays,
    Expression<String>? unitWeightKg,
    Expression<String>? unspscCode,
    Expression<String>? campaignId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (category != null) 'category': category,
      if (brand != null) 'brand': brand,
      if (form != null) 'form': form,
      if (strength != null) 'strength': strength,
      if (defaultUnit != null) 'default_unit': defaultUnit,
      if (gtin != null) 'gtin': gtin,
      if (innName != null) 'inn_name': innName,
      if (isControlled != null) 'is_controlled': isControlled,
      if (minShelfLifeDays != null) 'min_shelf_life_days': minShelfLifeDays,
      if (unitWeightKg != null) 'unit_weight_kg': unitWeightKg,
      if (unspscCode != null) 'unspsc_code': unspscCode,
      if (campaignId != null) 'campaign_id': campaignId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<String>? category,
    Value<String?>? brand,
    Value<String?>? form,
    Value<String?>? strength,
    Value<String?>? defaultUnit,
    Value<String?>? gtin,
    Value<String?>? innName,
    Value<bool>? isControlled,
    Value<int?>? minShelfLifeDays,
    Value<String?>? unitWeightKg,
    Value<String?>? unspscCode,
    Value<String?>? campaignId,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ProductTypesCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      form: form ?? this.form,
      strength: strength ?? this.strength,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      gtin: gtin ?? this.gtin,
      innName: innName ?? this.innName,
      isControlled: isControlled ?? this.isControlled,
      minShelfLifeDays: minShelfLifeDays ?? this.minShelfLifeDays,
      unitWeightKg: unitWeightKg ?? this.unitWeightKg,
      unspscCode: unspscCode ?? this.unspscCode,
      campaignId: campaignId ?? this.campaignId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (form.present) {
      map['form'] = Variable<String>(form.value);
    }
    if (strength.present) {
      map['strength'] = Variable<String>(strength.value);
    }
    if (defaultUnit.present) {
      map['default_unit'] = Variable<String>(defaultUnit.value);
    }
    if (gtin.present) {
      map['gtin'] = Variable<String>(gtin.value);
    }
    if (innName.present) {
      map['inn_name'] = Variable<String>(innName.value);
    }
    if (isControlled.present) {
      map['is_controlled'] = Variable<bool>(isControlled.value);
    }
    if (minShelfLifeDays.present) {
      map['min_shelf_life_days'] = Variable<int>(minShelfLifeDays.value);
    }
    if (unitWeightKg.present) {
      map['unit_weight_kg'] = Variable<String>(unitWeightKg.value);
    }
    if (unspscCode.present) {
      map['unspsc_code'] = Variable<String>(unspscCode.value);
    }
    if (campaignId.present) {
      map['campaign_id'] = Variable<String>(campaignId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductTypesCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('category: $category, ')
          ..write('brand: $brand, ')
          ..write('form: $form, ')
          ..write('strength: $strength, ')
          ..write('defaultUnit: $defaultUnit, ')
          ..write('gtin: $gtin, ')
          ..write('innName: $innName, ')
          ..write('isControlled: $isControlled, ')
          ..write('minShelfLifeDays: $minShelfLifeDays, ')
          ..write('unitWeightKg: $unitWeightKg, ')
          ..write('unspscCode: $unspscCode, ')
          ..write('campaignId: $campaignId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoxesTable extends Boxes with TableInfo<$BoxesTable, BoxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoxesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centerIdMeta = const VerificationMeta(
    'centerId',
  );
  @override
  late final GeneratedColumn<String> centerId = GeneratedColumn<String>(
    'center_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productTypeIdMeta = const VerificationMeta(
    'productTypeId',
  );
  @override
  late final GeneratedColumn<String> productTypeId = GeneratedColumn<String>(
    'product_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchMeta = const VerificationMeta('batch');
  @override
  late final GeneratedColumn<String> batch = GeneratedColumn<String>(
    'batch',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expiryDateMeta = const VerificationMeta(
    'expiryDate',
  );
  @override
  late final GeneratedColumn<DateTime> expiryDate = GeneratedColumn<DateTime>(
    'expiry_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<String> weightKg = GeneratedColumn<String>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sealedAtMeta = const VerificationMeta(
    'sealedAt',
  );
  @override
  late final GeneratedColumn<DateTime> sealedAt = GeneratedColumn<DateTime>(
    'sealed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _palletIdMeta = const VerificationMeta(
    'palletId',
  );
  @override
  late final GeneratedColumn<String> palletId = GeneratedColumn<String>(
    'pallet_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intakeIdMeta = const VerificationMeta(
    'intakeId',
  );
  @override
  late final GeneratedColumn<String> intakeId = GeneratedColumn<String>(
    'intake_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rejectReasonMeta = const VerificationMeta(
    'rejectReason',
  );
  @override
  late final GeneratedColumn<String> rejectReason = GeneratedColumn<String>(
    'reject_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    code,
    centerId,
    productTypeId,
    quantity,
    unit,
    status,
    batch,
    expiryDate,
    weightKg,
    sealedAt,
    palletId,
    intakeId,
    rejectReason,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'boxes';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('center_id')) {
      context.handle(
        _centerIdMeta,
        centerId.isAcceptableOrUnknown(data['center_id']!, _centerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_centerIdMeta);
    }
    if (data.containsKey('product_type_id')) {
      context.handle(
        _productTypeIdMeta,
        productTypeId.isAcceptableOrUnknown(
          data['product_type_id']!,
          _productTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productTypeIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('batch')) {
      context.handle(
        _batchMeta,
        batch.isAcceptableOrUnknown(data['batch']!, _batchMeta),
      );
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
        _expiryDateMeta,
        expiryDate.isAcceptableOrUnknown(data['expiry_date']!, _expiryDateMeta),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('sealed_at')) {
      context.handle(
        _sealedAtMeta,
        sealedAt.isAcceptableOrUnknown(data['sealed_at']!, _sealedAtMeta),
      );
    }
    if (data.containsKey('pallet_id')) {
      context.handle(
        _palletIdMeta,
        palletId.isAcceptableOrUnknown(data['pallet_id']!, _palletIdMeta),
      );
    }
    if (data.containsKey('intake_id')) {
      context.handle(
        _intakeIdMeta,
        intakeId.isAcceptableOrUnknown(data['intake_id']!, _intakeIdMeta),
      );
    }
    if (data.containsKey('reject_reason')) {
      context.handle(
        _rejectReasonMeta,
        rejectReason.isAcceptableOrUnknown(
          data['reject_reason']!,
          _rejectReasonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BoxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      centerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}center_id'],
      )!,
      productTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_type_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      batch: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch'],
      ),
      expiryDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiry_date'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_kg'],
      ),
      sealedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sealed_at'],
      ),
      palletId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pallet_id'],
      ),
      intakeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intake_id'],
      ),
      rejectReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reject_reason'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BoxesTable createAlias(String alias) {
    return $BoxesTable(attachedDatabase, alias);
  }
}

class BoxRow extends DataClass implements Insertable<BoxRow> {
  final String id;
  final String code;
  final String centerId;
  final String productTypeId;
  final int quantity;
  final String unit;
  final String status;
  final String? batch;
  final DateTime? expiryDate;

  /// Decimal del servidor, guardado como texto por la misma razón que el peso
  /// unitario del catálogo.
  final String? weightKg;
  final DateTime? sealedAt;
  final String? palletId;
  final String? intakeId;
  final String? rejectReason;
  final DateTime createdAt;
  const BoxRow({
    required this.id,
    required this.code,
    required this.centerId,
    required this.productTypeId,
    required this.quantity,
    required this.unit,
    required this.status,
    this.batch,
    this.expiryDate,
    this.weightKg,
    this.sealedAt,
    this.palletId,
    this.intakeId,
    this.rejectReason,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['code'] = Variable<String>(code);
    map['center_id'] = Variable<String>(centerId);
    map['product_type_id'] = Variable<String>(productTypeId);
    map['quantity'] = Variable<int>(quantity);
    map['unit'] = Variable<String>(unit);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || batch != null) {
      map['batch'] = Variable<String>(batch);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<DateTime>(expiryDate);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<String>(weightKg);
    }
    if (!nullToAbsent || sealedAt != null) {
      map['sealed_at'] = Variable<DateTime>(sealedAt);
    }
    if (!nullToAbsent || palletId != null) {
      map['pallet_id'] = Variable<String>(palletId);
    }
    if (!nullToAbsent || intakeId != null) {
      map['intake_id'] = Variable<String>(intakeId);
    }
    if (!nullToAbsent || rejectReason != null) {
      map['reject_reason'] = Variable<String>(rejectReason);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BoxesCompanion toCompanion(bool nullToAbsent) {
    return BoxesCompanion(
      id: Value(id),
      code: Value(code),
      centerId: Value(centerId),
      productTypeId: Value(productTypeId),
      quantity: Value(quantity),
      unit: Value(unit),
      status: Value(status),
      batch: batch == null && nullToAbsent
          ? const Value.absent()
          : Value(batch),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      sealedAt: sealedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sealedAt),
      palletId: palletId == null && nullToAbsent
          ? const Value.absent()
          : Value(palletId),
      intakeId: intakeId == null && nullToAbsent
          ? const Value.absent()
          : Value(intakeId),
      rejectReason: rejectReason == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectReason),
      createdAt: Value(createdAt),
    );
  }

  factory BoxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoxRow(
      id: serializer.fromJson<String>(json['id']),
      code: serializer.fromJson<String>(json['code']),
      centerId: serializer.fromJson<String>(json['centerId']),
      productTypeId: serializer.fromJson<String>(json['productTypeId']),
      quantity: serializer.fromJson<int>(json['quantity']),
      unit: serializer.fromJson<String>(json['unit']),
      status: serializer.fromJson<String>(json['status']),
      batch: serializer.fromJson<String?>(json['batch']),
      expiryDate: serializer.fromJson<DateTime?>(json['expiryDate']),
      weightKg: serializer.fromJson<String?>(json['weightKg']),
      sealedAt: serializer.fromJson<DateTime?>(json['sealedAt']),
      palletId: serializer.fromJson<String?>(json['palletId']),
      intakeId: serializer.fromJson<String?>(json['intakeId']),
      rejectReason: serializer.fromJson<String?>(json['rejectReason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'code': serializer.toJson<String>(code),
      'centerId': serializer.toJson<String>(centerId),
      'productTypeId': serializer.toJson<String>(productTypeId),
      'quantity': serializer.toJson<int>(quantity),
      'unit': serializer.toJson<String>(unit),
      'status': serializer.toJson<String>(status),
      'batch': serializer.toJson<String?>(batch),
      'expiryDate': serializer.toJson<DateTime?>(expiryDate),
      'weightKg': serializer.toJson<String?>(weightKg),
      'sealedAt': serializer.toJson<DateTime?>(sealedAt),
      'palletId': serializer.toJson<String?>(palletId),
      'intakeId': serializer.toJson<String?>(intakeId),
      'rejectReason': serializer.toJson<String?>(rejectReason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BoxRow copyWith({
    String? id,
    String? code,
    String? centerId,
    String? productTypeId,
    int? quantity,
    String? unit,
    String? status,
    Value<String?> batch = const Value.absent(),
    Value<DateTime?> expiryDate = const Value.absent(),
    Value<String?> weightKg = const Value.absent(),
    Value<DateTime?> sealedAt = const Value.absent(),
    Value<String?> palletId = const Value.absent(),
    Value<String?> intakeId = const Value.absent(),
    Value<String?> rejectReason = const Value.absent(),
    DateTime? createdAt,
  }) => BoxRow(
    id: id ?? this.id,
    code: code ?? this.code,
    centerId: centerId ?? this.centerId,
    productTypeId: productTypeId ?? this.productTypeId,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    status: status ?? this.status,
    batch: batch.present ? batch.value : this.batch,
    expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    sealedAt: sealedAt.present ? sealedAt.value : this.sealedAt,
    palletId: palletId.present ? palletId.value : this.palletId,
    intakeId: intakeId.present ? intakeId.value : this.intakeId,
    rejectReason: rejectReason.present ? rejectReason.value : this.rejectReason,
    createdAt: createdAt ?? this.createdAt,
  );
  BoxRow copyWithCompanion(BoxesCompanion data) {
    return BoxRow(
      id: data.id.present ? data.id.value : this.id,
      code: data.code.present ? data.code.value : this.code,
      centerId: data.centerId.present ? data.centerId.value : this.centerId,
      productTypeId: data.productTypeId.present
          ? data.productTypeId.value
          : this.productTypeId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      status: data.status.present ? data.status.value : this.status,
      batch: data.batch.present ? data.batch.value : this.batch,
      expiryDate: data.expiryDate.present
          ? data.expiryDate.value
          : this.expiryDate,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      sealedAt: data.sealedAt.present ? data.sealedAt.value : this.sealedAt,
      palletId: data.palletId.present ? data.palletId.value : this.palletId,
      intakeId: data.intakeId.present ? data.intakeId.value : this.intakeId,
      rejectReason: data.rejectReason.present
          ? data.rejectReason.value
          : this.rejectReason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoxRow(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('centerId: $centerId, ')
          ..write('productTypeId: $productTypeId, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('status: $status, ')
          ..write('batch: $batch, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('weightKg: $weightKg, ')
          ..write('sealedAt: $sealedAt, ')
          ..write('palletId: $palletId, ')
          ..write('intakeId: $intakeId, ')
          ..write('rejectReason: $rejectReason, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    code,
    centerId,
    productTypeId,
    quantity,
    unit,
    status,
    batch,
    expiryDate,
    weightKg,
    sealedAt,
    palletId,
    intakeId,
    rejectReason,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoxRow &&
          other.id == this.id &&
          other.code == this.code &&
          other.centerId == this.centerId &&
          other.productTypeId == this.productTypeId &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.status == this.status &&
          other.batch == this.batch &&
          other.expiryDate == this.expiryDate &&
          other.weightKg == this.weightKg &&
          other.sealedAt == this.sealedAt &&
          other.palletId == this.palletId &&
          other.intakeId == this.intakeId &&
          other.rejectReason == this.rejectReason &&
          other.createdAt == this.createdAt);
}

class BoxesCompanion extends UpdateCompanion<BoxRow> {
  final Value<String> id;
  final Value<String> code;
  final Value<String> centerId;
  final Value<String> productTypeId;
  final Value<int> quantity;
  final Value<String> unit;
  final Value<String> status;
  final Value<String?> batch;
  final Value<DateTime?> expiryDate;
  final Value<String?> weightKg;
  final Value<DateTime?> sealedAt;
  final Value<String?> palletId;
  final Value<String?> intakeId;
  final Value<String?> rejectReason;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BoxesCompanion({
    this.id = const Value.absent(),
    this.code = const Value.absent(),
    this.centerId = const Value.absent(),
    this.productTypeId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.status = const Value.absent(),
    this.batch = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.sealedAt = const Value.absent(),
    this.palletId = const Value.absent(),
    this.intakeId = const Value.absent(),
    this.rejectReason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoxesCompanion.insert({
    required String id,
    required String code,
    required String centerId,
    required String productTypeId,
    required int quantity,
    required String unit,
    required String status,
    this.batch = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.sealedAt = const Value.absent(),
    this.palletId = const Value.absent(),
    this.intakeId = const Value.absent(),
    this.rejectReason = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       code = Value(code),
       centerId = Value(centerId),
       productTypeId = Value(productTypeId),
       quantity = Value(quantity),
       unit = Value(unit),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<BoxRow> custom({
    Expression<String>? id,
    Expression<String>? code,
    Expression<String>? centerId,
    Expression<String>? productTypeId,
    Expression<int>? quantity,
    Expression<String>? unit,
    Expression<String>? status,
    Expression<String>? batch,
    Expression<DateTime>? expiryDate,
    Expression<String>? weightKg,
    Expression<DateTime>? sealedAt,
    Expression<String>? palletId,
    Expression<String>? intakeId,
    Expression<String>? rejectReason,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (code != null) 'code': code,
      if (centerId != null) 'center_id': centerId,
      if (productTypeId != null) 'product_type_id': productTypeId,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (status != null) 'status': status,
      if (batch != null) 'batch': batch,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (weightKg != null) 'weight_kg': weightKg,
      if (sealedAt != null) 'sealed_at': sealedAt,
      if (palletId != null) 'pallet_id': palletId,
      if (intakeId != null) 'intake_id': intakeId,
      if (rejectReason != null) 'reject_reason': rejectReason,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoxesCompanion copyWith({
    Value<String>? id,
    Value<String>? code,
    Value<String>? centerId,
    Value<String>? productTypeId,
    Value<int>? quantity,
    Value<String>? unit,
    Value<String>? status,
    Value<String?>? batch,
    Value<DateTime?>? expiryDate,
    Value<String?>? weightKg,
    Value<DateTime?>? sealedAt,
    Value<String?>? palletId,
    Value<String?>? intakeId,
    Value<String?>? rejectReason,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BoxesCompanion(
      id: id ?? this.id,
      code: code ?? this.code,
      centerId: centerId ?? this.centerId,
      productTypeId: productTypeId ?? this.productTypeId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      batch: batch ?? this.batch,
      expiryDate: expiryDate ?? this.expiryDate,
      weightKg: weightKg ?? this.weightKg,
      sealedAt: sealedAt ?? this.sealedAt,
      palletId: palletId ?? this.palletId,
      intakeId: intakeId ?? this.intakeId,
      rejectReason: rejectReason ?? this.rejectReason,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (centerId.present) {
      map['center_id'] = Variable<String>(centerId.value);
    }
    if (productTypeId.present) {
      map['product_type_id'] = Variable<String>(productTypeId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (batch.present) {
      map['batch'] = Variable<String>(batch.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<DateTime>(expiryDate.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<String>(weightKg.value);
    }
    if (sealedAt.present) {
      map['sealed_at'] = Variable<DateTime>(sealedAt.value);
    }
    if (palletId.present) {
      map['pallet_id'] = Variable<String>(palletId.value);
    }
    if (intakeId.present) {
      map['intake_id'] = Variable<String>(intakeId.value);
    }
    if (rejectReason.present) {
      map['reject_reason'] = Variable<String>(rejectReason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoxesCompanion(')
          ..write('id: $id, ')
          ..write('code: $code, ')
          ..write('centerId: $centerId, ')
          ..write('productTypeId: $productTypeId, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('status: $status, ')
          ..write('batch: $batch, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('weightKg: $weightKg, ')
          ..write('sealedAt: $sealedAt, ')
          ..write('palletId: $palletId, ')
          ..write('intakeId: $intakeId, ')
          ..write('rejectReason: $rejectReason, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMarkersTable extends SyncMarkers
    with TableInfo<$SyncMarkersTable, SyncMarkerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMarkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _resourceMeta = const VerificationMeta(
    'resource',
  );
  @override
  late final GeneratedColumn<String> resource = GeneratedColumn<String>(
    'resource',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFailureCodeMeta = const VerificationMeta(
    'lastFailureCode',
  );
  @override
  late final GeneratedColumn<String> lastFailureCode = GeneratedColumn<String>(
    'last_failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    resource,
    lastSyncedAt,
    lastFailureCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_markers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMarkerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('resource')) {
      context.handle(
        _resourceMeta,
        resource.isAcceptableOrUnknown(data['resource']!, _resourceMeta),
      );
    } else if (isInserting) {
      context.missing(_resourceMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_failure_code')) {
      context.handle(
        _lastFailureCodeMeta,
        lastFailureCode.isAcceptableOrUnknown(
          data['last_failure_code']!,
          _lastFailureCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {resource};
  @override
  SyncMarkerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMarkerRow(
      resource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resource'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      lastFailureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_failure_code'],
      ),
    );
  }

  @override
  $SyncMarkersTable createAlias(String alias) {
    return $SyncMarkersTable(attachedDatabase, alias);
  }
}

class SyncMarkerRow extends DataClass implements Insertable<SyncMarkerRow> {
  /// Identificador del recurso: `product_types`, `boxes`.
  final String resource;
  final DateTime? lastSyncedAt;
  final String? lastFailureCode;
  const SyncMarkerRow({
    required this.resource,
    this.lastSyncedAt,
    this.lastFailureCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['resource'] = Variable<String>(resource);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    if (!nullToAbsent || lastFailureCode != null) {
      map['last_failure_code'] = Variable<String>(lastFailureCode);
    }
    return map;
  }

  SyncMarkersCompanion toCompanion(bool nullToAbsent) {
    return SyncMarkersCompanion(
      resource: Value(resource),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      lastFailureCode: lastFailureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailureCode),
    );
  }

  factory SyncMarkerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMarkerRow(
      resource: serializer.fromJson<String>(json['resource']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      lastFailureCode: serializer.fromJson<String?>(json['lastFailureCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'resource': serializer.toJson<String>(resource),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'lastFailureCode': serializer.toJson<String?>(lastFailureCode),
    };
  }

  SyncMarkerRow copyWith({
    String? resource,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    Value<String?> lastFailureCode = const Value.absent(),
  }) => SyncMarkerRow(
    resource: resource ?? this.resource,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    lastFailureCode: lastFailureCode.present
        ? lastFailureCode.value
        : this.lastFailureCode,
  );
  SyncMarkerRow copyWithCompanion(SyncMarkersCompanion data) {
    return SyncMarkerRow(
      resource: data.resource.present ? data.resource.value : this.resource,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      lastFailureCode: data.lastFailureCode.present
          ? data.lastFailureCode.value
          : this.lastFailureCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMarkerRow(')
          ..write('resource: $resource, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastFailureCode: $lastFailureCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(resource, lastSyncedAt, lastFailureCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMarkerRow &&
          other.resource == this.resource &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.lastFailureCode == this.lastFailureCode);
}

class SyncMarkersCompanion extends UpdateCompanion<SyncMarkerRow> {
  final Value<String> resource;
  final Value<DateTime?> lastSyncedAt;
  final Value<String?> lastFailureCode;
  final Value<int> rowid;
  const SyncMarkersCompanion({
    this.resource = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.lastFailureCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMarkersCompanion.insert({
    required String resource,
    this.lastSyncedAt = const Value.absent(),
    this.lastFailureCode = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : resource = Value(resource);
  static Insertable<SyncMarkerRow> custom({
    Expression<String>? resource,
    Expression<DateTime>? lastSyncedAt,
    Expression<String>? lastFailureCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (resource != null) 'resource': resource,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (lastFailureCode != null) 'last_failure_code': lastFailureCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMarkersCompanion copyWith({
    Value<String>? resource,
    Value<DateTime?>? lastSyncedAt,
    Value<String?>? lastFailureCode,
    Value<int>? rowid,
  }) {
    return SyncMarkersCompanion(
      resource: resource ?? this.resource,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      lastFailureCode: lastFailureCode ?? this.lastFailureCode,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (resource.present) {
      map['resource'] = Variable<String>(resource.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (lastFailureCode.present) {
      map['last_failure_code'] = Variable<String>(lastFailureCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMarkersCompanion(')
          ..write('resource: $resource, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('lastFailureCode: $lastFailureCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueuedCapturesTable extends QueuedCaptures
    with TableInfo<$QueuedCapturesTable, QueuedCaptureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueuedCapturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _captureIdMeta = const VerificationMeta(
    'captureId',
  );
  @override
  late final GeneratedColumn<String> captureId = GeneratedColumn<String>(
    'capture_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _boxCountMeta = const VerificationMeta(
    'boxCount',
  );
  @override
  late final GeneratedColumn<int> boxCount = GeneratedColumn<int>(
    'box_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<QueuedCaptureStatus, String>
  status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<QueuedCaptureStatus>($QueuedCapturesTable.$converterstatus);
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastFailureCodeMeta = const VerificationMeta(
    'lastFailureCode',
  );
  @override
  late final GeneratedColumn<String> lastFailureCode = GeneratedColumn<String>(
    'last_failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastFailureMessageMeta =
      const VerificationMeta('lastFailureMessage');
  @override
  late final GeneratedColumn<String> lastFailureMessage =
      GeneratedColumn<String>(
        'last_failure_message',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    captureId,
    userId,
    payload,
    summary,
    boxCount,
    status,
    attempts,
    lastFailureCode,
    lastFailureMessage,
    createdAt,
    lastAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queued_captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<QueuedCaptureRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('capture_id')) {
      context.handle(
        _captureIdMeta,
        captureId.isAcceptableOrUnknown(data['capture_id']!, _captureIdMeta),
      );
    } else if (isInserting) {
      context.missing(_captureIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('box_count')) {
      context.handle(
        _boxCountMeta,
        boxCount.isAcceptableOrUnknown(data['box_count']!, _boxCountMeta),
      );
    } else if (isInserting) {
      context.missing(_boxCountMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_failure_code')) {
      context.handle(
        _lastFailureCodeMeta,
        lastFailureCode.isAcceptableOrUnknown(
          data['last_failure_code']!,
          _lastFailureCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_failure_message')) {
      context.handle(
        _lastFailureMessageMeta,
        lastFailureMessage.isAcceptableOrUnknown(
          data['last_failure_message']!,
          _lastFailureMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {captureId};
  @override
  QueuedCaptureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueuedCaptureRow(
      captureId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}capture_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      boxCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}box_count'],
      )!,
      status: $QueuedCapturesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastFailureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_failure_code'],
      ),
      lastFailureMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_failure_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
    );
  }

  @override
  $QueuedCapturesTable createAlias(String alias) {
    return $QueuedCapturesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<QueuedCaptureStatus, String, String>
  $converterstatus = const EnumNameConverter<QueuedCaptureStatus>(
    QueuedCaptureStatus.values,
  );
}

class QueuedCaptureRow extends DataClass
    implements Insertable<QueuedCaptureRow> {
  final String captureId;
  final String userId;

  /// Cuerpo de `POST /v1/intakes` serializado.
  final String payload;

  /// Resumen legible para la pantalla de pendientes, calculado al encolar: no
  /// hace falta volver a interpretar el payload para decir qué hay dentro.
  final String summary;
  final int boxCount;
  final QueuedCaptureStatus status;
  final int attempts;

  /// Código y mensaje del último rechazo, para que la pantalla muestre el
  /// motivo del servidor tal cual.
  final String? lastFailureCode;
  final String? lastFailureMessage;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  const QueuedCaptureRow({
    required this.captureId,
    required this.userId,
    required this.payload,
    required this.summary,
    required this.boxCount,
    required this.status,
    required this.attempts,
    this.lastFailureCode,
    this.lastFailureMessage,
    required this.createdAt,
    this.lastAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['capture_id'] = Variable<String>(captureId);
    map['user_id'] = Variable<String>(userId);
    map['payload'] = Variable<String>(payload);
    map['summary'] = Variable<String>(summary);
    map['box_count'] = Variable<int>(boxCount);
    {
      map['status'] = Variable<String>(
        $QueuedCapturesTable.$converterstatus.toSql(status),
      );
    }
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastFailureCode != null) {
      map['last_failure_code'] = Variable<String>(lastFailureCode);
    }
    if (!nullToAbsent || lastFailureMessage != null) {
      map['last_failure_message'] = Variable<String>(lastFailureMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  QueuedCapturesCompanion toCompanion(bool nullToAbsent) {
    return QueuedCapturesCompanion(
      captureId: Value(captureId),
      userId: Value(userId),
      payload: Value(payload),
      summary: Value(summary),
      boxCount: Value(boxCount),
      status: Value(status),
      attempts: Value(attempts),
      lastFailureCode: lastFailureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailureCode),
      lastFailureMessage: lastFailureMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFailureMessage),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory QueuedCaptureRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueuedCaptureRow(
      captureId: serializer.fromJson<String>(json['captureId']),
      userId: serializer.fromJson<String>(json['userId']),
      payload: serializer.fromJson<String>(json['payload']),
      summary: serializer.fromJson<String>(json['summary']),
      boxCount: serializer.fromJson<int>(json['boxCount']),
      status: $QueuedCapturesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastFailureCode: serializer.fromJson<String?>(json['lastFailureCode']),
      lastFailureMessage: serializer.fromJson<String?>(
        json['lastFailureMessage'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'captureId': serializer.toJson<String>(captureId),
      'userId': serializer.toJson<String>(userId),
      'payload': serializer.toJson<String>(payload),
      'summary': serializer.toJson<String>(summary),
      'boxCount': serializer.toJson<int>(boxCount),
      'status': serializer.toJson<String>(
        $QueuedCapturesTable.$converterstatus.toJson(status),
      ),
      'attempts': serializer.toJson<int>(attempts),
      'lastFailureCode': serializer.toJson<String?>(lastFailureCode),
      'lastFailureMessage': serializer.toJson<String?>(lastFailureMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  QueuedCaptureRow copyWith({
    String? captureId,
    String? userId,
    String? payload,
    String? summary,
    int? boxCount,
    QueuedCaptureStatus? status,
    int? attempts,
    Value<String?> lastFailureCode = const Value.absent(),
    Value<String?> lastFailureMessage = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
  }) => QueuedCaptureRow(
    captureId: captureId ?? this.captureId,
    userId: userId ?? this.userId,
    payload: payload ?? this.payload,
    summary: summary ?? this.summary,
    boxCount: boxCount ?? this.boxCount,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastFailureCode: lastFailureCode.present
        ? lastFailureCode.value
        : this.lastFailureCode,
    lastFailureMessage: lastFailureMessage.present
        ? lastFailureMessage.value
        : this.lastFailureMessage,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
  );
  QueuedCaptureRow copyWithCompanion(QueuedCapturesCompanion data) {
    return QueuedCaptureRow(
      captureId: data.captureId.present ? data.captureId.value : this.captureId,
      userId: data.userId.present ? data.userId.value : this.userId,
      payload: data.payload.present ? data.payload.value : this.payload,
      summary: data.summary.present ? data.summary.value : this.summary,
      boxCount: data.boxCount.present ? data.boxCount.value : this.boxCount,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastFailureCode: data.lastFailureCode.present
          ? data.lastFailureCode.value
          : this.lastFailureCode,
      lastFailureMessage: data.lastFailureMessage.present
          ? data.lastFailureMessage.value
          : this.lastFailureMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueuedCaptureRow(')
          ..write('captureId: $captureId, ')
          ..write('userId: $userId, ')
          ..write('payload: $payload, ')
          ..write('summary: $summary, ')
          ..write('boxCount: $boxCount, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastFailureCode: $lastFailureCode, ')
          ..write('lastFailureMessage: $lastFailureMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    captureId,
    userId,
    payload,
    summary,
    boxCount,
    status,
    attempts,
    lastFailureCode,
    lastFailureMessage,
    createdAt,
    lastAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueuedCaptureRow &&
          other.captureId == this.captureId &&
          other.userId == this.userId &&
          other.payload == this.payload &&
          other.summary == this.summary &&
          other.boxCount == this.boxCount &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastFailureCode == this.lastFailureCode &&
          other.lastFailureMessage == this.lastFailureMessage &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class QueuedCapturesCompanion extends UpdateCompanion<QueuedCaptureRow> {
  final Value<String> captureId;
  final Value<String> userId;
  final Value<String> payload;
  final Value<String> summary;
  final Value<int> boxCount;
  final Value<QueuedCaptureStatus> status;
  final Value<int> attempts;
  final Value<String?> lastFailureCode;
  final Value<String?> lastFailureMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> rowid;
  const QueuedCapturesCompanion({
    this.captureId = const Value.absent(),
    this.userId = const Value.absent(),
    this.payload = const Value.absent(),
    this.summary = const Value.absent(),
    this.boxCount = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastFailureCode = const Value.absent(),
    this.lastFailureMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueuedCapturesCompanion.insert({
    required String captureId,
    required String userId,
    required String payload,
    required String summary,
    required int boxCount,
    required QueuedCaptureStatus status,
    this.attempts = const Value.absent(),
    this.lastFailureCode = const Value.absent(),
    this.lastFailureMessage = const Value.absent(),
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : captureId = Value(captureId),
       userId = Value(userId),
       payload = Value(payload),
       summary = Value(summary),
       boxCount = Value(boxCount),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<QueuedCaptureRow> custom({
    Expression<String>? captureId,
    Expression<String>? userId,
    Expression<String>? payload,
    Expression<String>? summary,
    Expression<int>? boxCount,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastFailureCode,
    Expression<String>? lastFailureMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (captureId != null) 'capture_id': captureId,
      if (userId != null) 'user_id': userId,
      if (payload != null) 'payload': payload,
      if (summary != null) 'summary': summary,
      if (boxCount != null) 'box_count': boxCount,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastFailureCode != null) 'last_failure_code': lastFailureCode,
      if (lastFailureMessage != null)
        'last_failure_message': lastFailureMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueuedCapturesCompanion copyWith({
    Value<String>? captureId,
    Value<String>? userId,
    Value<String>? payload,
    Value<String>? summary,
    Value<int>? boxCount,
    Value<QueuedCaptureStatus>? status,
    Value<int>? attempts,
    Value<String?>? lastFailureCode,
    Value<String?>? lastFailureMessage,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<int>? rowid,
  }) {
    return QueuedCapturesCompanion(
      captureId: captureId ?? this.captureId,
      userId: userId ?? this.userId,
      payload: payload ?? this.payload,
      summary: summary ?? this.summary,
      boxCount: boxCount ?? this.boxCount,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastFailureCode: lastFailureCode ?? this.lastFailureCode,
      lastFailureMessage: lastFailureMessage ?? this.lastFailureMessage,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (captureId.present) {
      map['capture_id'] = Variable<String>(captureId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (boxCount.present) {
      map['box_count'] = Variable<int>(boxCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $QueuedCapturesTable.$converterstatus.toSql(status.value),
      );
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastFailureCode.present) {
      map['last_failure_code'] = Variable<String>(lastFailureCode.value);
    }
    if (lastFailureMessage.present) {
      map['last_failure_message'] = Variable<String>(lastFailureMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueuedCapturesCompanion(')
          ..write('captureId: $captureId, ')
          ..write('userId: $userId, ')
          ..write('payload: $payload, ')
          ..write('summary: $summary, ')
          ..write('boxCount: $boxCount, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastFailureCode: $lastFailureCode, ')
          ..write('lastFailureMessage: $lastFailureMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoxCodeReservationsTable extends BoxCodeReservations
    with TableInfo<$BoxCodeReservationsTable, BoxCodeReservationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoxCodeReservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _centerIdMeta = const VerificationMeta(
    'centerId',
  );
  @override
  late final GeneratedColumn<String> centerId = GeneratedColumn<String>(
    'center_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reservedAtMeta = const VerificationMeta(
    'reservedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reservedAt = GeneratedColumn<DateTime>(
    'reserved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spentAtMeta = const VerificationMeta(
    'spentAt',
  );
  @override
  late final GeneratedColumn<DateTime> spentAt = GeneratedColumn<DateTime>(
    'spent_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    code,
    userId,
    centerId,
    reservedAt,
    spentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'box_code_reservations';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoxCodeReservationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('center_id')) {
      context.handle(
        _centerIdMeta,
        centerId.isAcceptableOrUnknown(data['center_id']!, _centerIdMeta),
      );
    }
    if (data.containsKey('reserved_at')) {
      context.handle(
        _reservedAtMeta,
        reservedAt.isAcceptableOrUnknown(data['reserved_at']!, _reservedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reservedAtMeta);
    }
    if (data.containsKey('spent_at')) {
      context.handle(
        _spentAtMeta,
        spentAt.isAcceptableOrUnknown(data['spent_at']!, _spentAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  BoxCodeReservationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoxCodeReservationRow(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      centerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}center_id'],
      ),
      reservedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reserved_at'],
      )!,
      spentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}spent_at'],
      ),
    );
  }

  @override
  $BoxCodeReservationsTable createAlias(String alias) {
    return $BoxCodeReservationsTable(attachedDatabase, alias);
  }
}

class BoxCodeReservationRow extends DataClass
    implements Insertable<BoxCodeReservationRow> {
  final String code;

  /// Quién lo reservó. La cola es por persona y los códigos también: en un
  /// dispositivo compartido, dos turnos no pueden repartirse el mismo bloque.
  final String userId;

  /// Which centre the block was reserved for.
  ///
  /// The server hands out codes **for a centre**, so spending them in another
  /// one puts the wrong centre's label on a physical box. A national
  /// administrator can change working centre with a block half spent, and
  /// without this column the rest of it would be spent there.
  ///
  /// Null in rows written before this column existed, and those are spendable
  /// anywhere. That is not a convenient exception: reserving has always
  /// required belonging to a centre — the server refuses anybody who has none —
  /// so a row without one can only belong to somebody who had exactly one.
  final String? centerId;
  final DateTime reservedAt;
  final DateTime? spentAt;
  const BoxCodeReservationRow({
    required this.code,
    required this.userId,
    this.centerId,
    required this.reservedAt,
    this.spentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || centerId != null) {
      map['center_id'] = Variable<String>(centerId);
    }
    map['reserved_at'] = Variable<DateTime>(reservedAt);
    if (!nullToAbsent || spentAt != null) {
      map['spent_at'] = Variable<DateTime>(spentAt);
    }
    return map;
  }

  BoxCodeReservationsCompanion toCompanion(bool nullToAbsent) {
    return BoxCodeReservationsCompanion(
      code: Value(code),
      userId: Value(userId),
      centerId: centerId == null && nullToAbsent
          ? const Value.absent()
          : Value(centerId),
      reservedAt: Value(reservedAt),
      spentAt: spentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(spentAt),
    );
  }

  factory BoxCodeReservationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoxCodeReservationRow(
      code: serializer.fromJson<String>(json['code']),
      userId: serializer.fromJson<String>(json['userId']),
      centerId: serializer.fromJson<String?>(json['centerId']),
      reservedAt: serializer.fromJson<DateTime>(json['reservedAt']),
      spentAt: serializer.fromJson<DateTime?>(json['spentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'userId': serializer.toJson<String>(userId),
      'centerId': serializer.toJson<String?>(centerId),
      'reservedAt': serializer.toJson<DateTime>(reservedAt),
      'spentAt': serializer.toJson<DateTime?>(spentAt),
    };
  }

  BoxCodeReservationRow copyWith({
    String? code,
    String? userId,
    Value<String?> centerId = const Value.absent(),
    DateTime? reservedAt,
    Value<DateTime?> spentAt = const Value.absent(),
  }) => BoxCodeReservationRow(
    code: code ?? this.code,
    userId: userId ?? this.userId,
    centerId: centerId.present ? centerId.value : this.centerId,
    reservedAt: reservedAt ?? this.reservedAt,
    spentAt: spentAt.present ? spentAt.value : this.spentAt,
  );
  BoxCodeReservationRow copyWithCompanion(BoxCodeReservationsCompanion data) {
    return BoxCodeReservationRow(
      code: data.code.present ? data.code.value : this.code,
      userId: data.userId.present ? data.userId.value : this.userId,
      centerId: data.centerId.present ? data.centerId.value : this.centerId,
      reservedAt: data.reservedAt.present
          ? data.reservedAt.value
          : this.reservedAt,
      spentAt: data.spentAt.present ? data.spentAt.value : this.spentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoxCodeReservationRow(')
          ..write('code: $code, ')
          ..write('userId: $userId, ')
          ..write('centerId: $centerId, ')
          ..write('reservedAt: $reservedAt, ')
          ..write('spentAt: $spentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, userId, centerId, reservedAt, spentAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoxCodeReservationRow &&
          other.code == this.code &&
          other.userId == this.userId &&
          other.centerId == this.centerId &&
          other.reservedAt == this.reservedAt &&
          other.spentAt == this.spentAt);
}

class BoxCodeReservationsCompanion
    extends UpdateCompanion<BoxCodeReservationRow> {
  final Value<String> code;
  final Value<String> userId;
  final Value<String?> centerId;
  final Value<DateTime> reservedAt;
  final Value<DateTime?> spentAt;
  final Value<int> rowid;
  const BoxCodeReservationsCompanion({
    this.code = const Value.absent(),
    this.userId = const Value.absent(),
    this.centerId = const Value.absent(),
    this.reservedAt = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoxCodeReservationsCompanion.insert({
    required String code,
    required String userId,
    this.centerId = const Value.absent(),
    required DateTime reservedAt,
    this.spentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       userId = Value(userId),
       reservedAt = Value(reservedAt);
  static Insertable<BoxCodeReservationRow> custom({
    Expression<String>? code,
    Expression<String>? userId,
    Expression<String>? centerId,
    Expression<DateTime>? reservedAt,
    Expression<DateTime>? spentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (userId != null) 'user_id': userId,
      if (centerId != null) 'center_id': centerId,
      if (reservedAt != null) 'reserved_at': reservedAt,
      if (spentAt != null) 'spent_at': spentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoxCodeReservationsCompanion copyWith({
    Value<String>? code,
    Value<String>? userId,
    Value<String?>? centerId,
    Value<DateTime>? reservedAt,
    Value<DateTime?>? spentAt,
    Value<int>? rowid,
  }) {
    return BoxCodeReservationsCompanion(
      code: code ?? this.code,
      userId: userId ?? this.userId,
      centerId: centerId ?? this.centerId,
      reservedAt: reservedAt ?? this.reservedAt,
      spentAt: spentAt ?? this.spentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (centerId.present) {
      map['center_id'] = Variable<String>(centerId.value);
    }
    if (reservedAt.present) {
      map['reserved_at'] = Variable<DateTime>(reservedAt.value);
    }
    if (spentAt.present) {
      map['spent_at'] = Variable<DateTime>(spentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoxCodeReservationsCompanion(')
          ..write('code: $code, ')
          ..write('userId: $userId, ')
          ..write('centerId: $centerId, ')
          ..write('reservedAt: $reservedAt, ')
          ..write('spentAt: $spentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductTypesTable productTypes = $ProductTypesTable(this);
  late final $BoxesTable boxes = $BoxesTable(this);
  late final $SyncMarkersTable syncMarkers = $SyncMarkersTable(this);
  late final $QueuedCapturesTable queuedCaptures = $QueuedCapturesTable(this);
  late final $BoxCodeReservationsTable boxCodeReservations =
      $BoxCodeReservationsTable(this);
  late final CatalogDao catalogDao = CatalogDao(this as AppDatabase);
  late final BoxesDao boxesDao = BoxesDao(this as AppDatabase);
  late final SyncMarkersDao syncMarkersDao = SyncMarkersDao(
    this as AppDatabase,
  );
  late final CaptureQueueDao captureQueueDao = CaptureQueueDao(
    this as AppDatabase,
  );
  late final BoxCodesDao boxCodesDao = BoxCodesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productTypes,
    boxes,
    syncMarkers,
    queuedCaptures,
    boxCodeReservations,
  ];
}

typedef $$ProductTypesTableCreateCompanionBuilder =
    ProductTypesCompanion Function({
      required String id,
      required String displayName,
      required String category,
      Value<String?> brand,
      Value<String?> form,
      Value<String?> strength,
      Value<String?> defaultUnit,
      Value<String?> gtin,
      Value<String?> innName,
      required bool isControlled,
      Value<int?> minShelfLifeDays,
      Value<String?> unitWeightKg,
      Value<String?> unspscCode,
      Value<String?> campaignId,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$ProductTypesTableUpdateCompanionBuilder =
    ProductTypesCompanion Function({
      Value<String> id,
      Value<String> displayName,
      Value<String> category,
      Value<String?> brand,
      Value<String?> form,
      Value<String?> strength,
      Value<String?> defaultUnit,
      Value<String?> gtin,
      Value<String?> innName,
      Value<bool> isControlled,
      Value<int?> minShelfLifeDays,
      Value<String?> unitWeightKg,
      Value<String?> unspscCode,
      Value<String?> campaignId,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ProductTypesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductTypesTable> {
  $$ProductTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gtin => $composableBuilder(
    column: $table.gtin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get innName => $composableBuilder(
    column: $table.innName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isControlled => $composableBuilder(
    column: $table.isControlled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minShelfLifeDays => $composableBuilder(
    column: $table.minShelfLifeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitWeightKg => $composableBuilder(
    column: $table.unitWeightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unspscCode => $composableBuilder(
    column: $table.unspscCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get campaignId => $composableBuilder(
    column: $table.campaignId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductTypesTable> {
  $$ProductTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get form => $composableBuilder(
    column: $table.form,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gtin => $composableBuilder(
    column: $table.gtin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get innName => $composableBuilder(
    column: $table.innName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isControlled => $composableBuilder(
    column: $table.isControlled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minShelfLifeDays => $composableBuilder(
    column: $table.minShelfLifeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitWeightKg => $composableBuilder(
    column: $table.unitWeightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unspscCode => $composableBuilder(
    column: $table.unspscCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get campaignId => $composableBuilder(
    column: $table.campaignId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductTypesTable> {
  $$ProductTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get form =>
      $composableBuilder(column: $table.form, builder: (column) => column);

  GeneratedColumn<String> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gtin =>
      $composableBuilder(column: $table.gtin, builder: (column) => column);

  GeneratedColumn<String> get innName =>
      $composableBuilder(column: $table.innName, builder: (column) => column);

  GeneratedColumn<bool> get isControlled => $composableBuilder(
    column: $table.isControlled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minShelfLifeDays => $composableBuilder(
    column: $table.minShelfLifeDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitWeightKg => $composableBuilder(
    column: $table.unitWeightKg,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unspscCode => $composableBuilder(
    column: $table.unspscCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get campaignId => $composableBuilder(
    column: $table.campaignId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProductTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductTypesTable,
          ProductTypeRow,
          $$ProductTypesTableFilterComposer,
          $$ProductTypesTableOrderingComposer,
          $$ProductTypesTableAnnotationComposer,
          $$ProductTypesTableCreateCompanionBuilder,
          $$ProductTypesTableUpdateCompanionBuilder,
          (
            ProductTypeRow,
            BaseReferences<_$AppDatabase, $ProductTypesTable, ProductTypeRow>,
          ),
          ProductTypeRow,
          PrefetchHooks Function()
        > {
  $$ProductTypesTableTableManager(_$AppDatabase db, $ProductTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> form = const Value.absent(),
                Value<String?> strength = const Value.absent(),
                Value<String?> defaultUnit = const Value.absent(),
                Value<String?> gtin = const Value.absent(),
                Value<String?> innName = const Value.absent(),
                Value<bool> isControlled = const Value.absent(),
                Value<int?> minShelfLifeDays = const Value.absent(),
                Value<String?> unitWeightKg = const Value.absent(),
                Value<String?> unspscCode = const Value.absent(),
                Value<String?> campaignId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductTypesCompanion(
                id: id,
                displayName: displayName,
                category: category,
                brand: brand,
                form: form,
                strength: strength,
                defaultUnit: defaultUnit,
                gtin: gtin,
                innName: innName,
                isControlled: isControlled,
                minShelfLifeDays: minShelfLifeDays,
                unitWeightKg: unitWeightKg,
                unspscCode: unspscCode,
                campaignId: campaignId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                required String category,
                Value<String?> brand = const Value.absent(),
                Value<String?> form = const Value.absent(),
                Value<String?> strength = const Value.absent(),
                Value<String?> defaultUnit = const Value.absent(),
                Value<String?> gtin = const Value.absent(),
                Value<String?> innName = const Value.absent(),
                required bool isControlled,
                Value<int?> minShelfLifeDays = const Value.absent(),
                Value<String?> unitWeightKg = const Value.absent(),
                Value<String?> unspscCode = const Value.absent(),
                Value<String?> campaignId = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductTypesCompanion.insert(
                id: id,
                displayName: displayName,
                category: category,
                brand: brand,
                form: form,
                strength: strength,
                defaultUnit: defaultUnit,
                gtin: gtin,
                innName: innName,
                isControlled: isControlled,
                minShelfLifeDays: minShelfLifeDays,
                unitWeightKg: unitWeightKg,
                unspscCode: unspscCode,
                campaignId: campaignId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductTypesTable,
      ProductTypeRow,
      $$ProductTypesTableFilterComposer,
      $$ProductTypesTableOrderingComposer,
      $$ProductTypesTableAnnotationComposer,
      $$ProductTypesTableCreateCompanionBuilder,
      $$ProductTypesTableUpdateCompanionBuilder,
      (
        ProductTypeRow,
        BaseReferences<_$AppDatabase, $ProductTypesTable, ProductTypeRow>,
      ),
      ProductTypeRow,
      PrefetchHooks Function()
    >;
typedef $$BoxesTableCreateCompanionBuilder =
    BoxesCompanion Function({
      required String id,
      required String code,
      required String centerId,
      required String productTypeId,
      required int quantity,
      required String unit,
      required String status,
      Value<String?> batch,
      Value<DateTime?> expiryDate,
      Value<String?> weightKg,
      Value<DateTime?> sealedAt,
      Value<String?> palletId,
      Value<String?> intakeId,
      Value<String?> rejectReason,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BoxesTableUpdateCompanionBuilder =
    BoxesCompanion Function({
      Value<String> id,
      Value<String> code,
      Value<String> centerId,
      Value<String> productTypeId,
      Value<int> quantity,
      Value<String> unit,
      Value<String> status,
      Value<String?> batch,
      Value<DateTime?> expiryDate,
      Value<String?> weightKg,
      Value<DateTime?> sealedAt,
      Value<String?> palletId,
      Value<String?> intakeId,
      Value<String?> rejectReason,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$BoxesTableFilterComposer extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get centerId => $composableBuilder(
    column: $table.centerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productTypeId => $composableBuilder(
    column: $table.productTypeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batch => $composableBuilder(
    column: $table.batch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sealedAt => $composableBuilder(
    column: $table.sealedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get palletId => $composableBuilder(
    column: $table.palletId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intakeId => $composableBuilder(
    column: $table.intakeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoxesTableOrderingComposer
    extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get centerId => $composableBuilder(
    column: $table.centerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productTypeId => $composableBuilder(
    column: $table.productTypeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batch => $composableBuilder(
    column: $table.batch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sealedAt => $composableBuilder(
    column: $table.sealedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get palletId => $composableBuilder(
    column: $table.palletId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intakeId => $composableBuilder(
    column: $table.intakeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoxesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoxesTable> {
  $$BoxesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get centerId =>
      $composableBuilder(column: $table.centerId, builder: (column) => column);

  GeneratedColumn<String> get productTypeId => $composableBuilder(
    column: $table.productTypeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get batch =>
      $composableBuilder(column: $table.batch, builder: (column) => column);

  GeneratedColumn<DateTime> get expiryDate => $composableBuilder(
    column: $table.expiryDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<DateTime> get sealedAt =>
      $composableBuilder(column: $table.sealedAt, builder: (column) => column);

  GeneratedColumn<String> get palletId =>
      $composableBuilder(column: $table.palletId, builder: (column) => column);

  GeneratedColumn<String> get intakeId =>
      $composableBuilder(column: $table.intakeId, builder: (column) => column);

  GeneratedColumn<String> get rejectReason => $composableBuilder(
    column: $table.rejectReason,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BoxesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoxesTable,
          BoxRow,
          $$BoxesTableFilterComposer,
          $$BoxesTableOrderingComposer,
          $$BoxesTableAnnotationComposer,
          $$BoxesTableCreateCompanionBuilder,
          $$BoxesTableUpdateCompanionBuilder,
          (BoxRow, BaseReferences<_$AppDatabase, $BoxesTable, BoxRow>),
          BoxRow,
          PrefetchHooks Function()
        > {
  $$BoxesTableTableManager(_$AppDatabase db, $BoxesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoxesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoxesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoxesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> centerId = const Value.absent(),
                Value<String> productTypeId = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> batch = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<String?> weightKg = const Value.absent(),
                Value<DateTime?> sealedAt = const Value.absent(),
                Value<String?> palletId = const Value.absent(),
                Value<String?> intakeId = const Value.absent(),
                Value<String?> rejectReason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoxesCompanion(
                id: id,
                code: code,
                centerId: centerId,
                productTypeId: productTypeId,
                quantity: quantity,
                unit: unit,
                status: status,
                batch: batch,
                expiryDate: expiryDate,
                weightKg: weightKg,
                sealedAt: sealedAt,
                palletId: palletId,
                intakeId: intakeId,
                rejectReason: rejectReason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String code,
                required String centerId,
                required String productTypeId,
                required int quantity,
                required String unit,
                required String status,
                Value<String?> batch = const Value.absent(),
                Value<DateTime?> expiryDate = const Value.absent(),
                Value<String?> weightKg = const Value.absent(),
                Value<DateTime?> sealedAt = const Value.absent(),
                Value<String?> palletId = const Value.absent(),
                Value<String?> intakeId = const Value.absent(),
                Value<String?> rejectReason = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BoxesCompanion.insert(
                id: id,
                code: code,
                centerId: centerId,
                productTypeId: productTypeId,
                quantity: quantity,
                unit: unit,
                status: status,
                batch: batch,
                expiryDate: expiryDate,
                weightKg: weightKg,
                sealedAt: sealedAt,
                palletId: palletId,
                intakeId: intakeId,
                rejectReason: rejectReason,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoxesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoxesTable,
      BoxRow,
      $$BoxesTableFilterComposer,
      $$BoxesTableOrderingComposer,
      $$BoxesTableAnnotationComposer,
      $$BoxesTableCreateCompanionBuilder,
      $$BoxesTableUpdateCompanionBuilder,
      (BoxRow, BaseReferences<_$AppDatabase, $BoxesTable, BoxRow>),
      BoxRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMarkersTableCreateCompanionBuilder =
    SyncMarkersCompanion Function({
      required String resource,
      Value<DateTime?> lastSyncedAt,
      Value<String?> lastFailureCode,
      Value<int> rowid,
    });
typedef $$SyncMarkersTableUpdateCompanionBuilder =
    SyncMarkersCompanion Function({
      Value<String> resource,
      Value<DateTime?> lastSyncedAt,
      Value<String?> lastFailureCode,
      Value<int> rowid,
    });

class $$SyncMarkersTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMarkersTable> {
  $$SyncMarkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get resource => $composableBuilder(
    column: $table.resource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFailureCode => $composableBuilder(
    column: $table.lastFailureCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMarkersTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMarkersTable> {
  $$SyncMarkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get resource => $composableBuilder(
    column: $table.resource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFailureCode => $composableBuilder(
    column: $table.lastFailureCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMarkersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMarkersTable> {
  $$SyncMarkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get resource =>
      $composableBuilder(column: $table.resource, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastFailureCode => $composableBuilder(
    column: $table.lastFailureCode,
    builder: (column) => column,
  );
}

class $$SyncMarkersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMarkersTable,
          SyncMarkerRow,
          $$SyncMarkersTableFilterComposer,
          $$SyncMarkersTableOrderingComposer,
          $$SyncMarkersTableAnnotationComposer,
          $$SyncMarkersTableCreateCompanionBuilder,
          $$SyncMarkersTableUpdateCompanionBuilder,
          (
            SyncMarkerRow,
            BaseReferences<_$AppDatabase, $SyncMarkersTable, SyncMarkerRow>,
          ),
          SyncMarkerRow,
          PrefetchHooks Function()
        > {
  $$SyncMarkersTableTableManager(_$AppDatabase db, $SyncMarkersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMarkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMarkersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMarkersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> resource = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> lastFailureCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMarkersCompanion(
                resource: resource,
                lastSyncedAt: lastSyncedAt,
                lastFailureCode: lastFailureCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String resource,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<String?> lastFailureCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMarkersCompanion.insert(
                resource: resource,
                lastSyncedAt: lastSyncedAt,
                lastFailureCode: lastFailureCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMarkersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMarkersTable,
      SyncMarkerRow,
      $$SyncMarkersTableFilterComposer,
      $$SyncMarkersTableOrderingComposer,
      $$SyncMarkersTableAnnotationComposer,
      $$SyncMarkersTableCreateCompanionBuilder,
      $$SyncMarkersTableUpdateCompanionBuilder,
      (
        SyncMarkerRow,
        BaseReferences<_$AppDatabase, $SyncMarkersTable, SyncMarkerRow>,
      ),
      SyncMarkerRow,
      PrefetchHooks Function()
    >;
typedef $$QueuedCapturesTableCreateCompanionBuilder =
    QueuedCapturesCompanion Function({
      required String captureId,
      required String userId,
      required String payload,
      required String summary,
      required int boxCount,
      required QueuedCaptureStatus status,
      Value<int> attempts,
      Value<String?> lastFailureCode,
      Value<String?> lastFailureMessage,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> rowid,
    });
typedef $$QueuedCapturesTableUpdateCompanionBuilder =
    QueuedCapturesCompanion Function({
      Value<String> captureId,
      Value<String> userId,
      Value<String> payload,
      Value<String> summary,
      Value<int> boxCount,
      Value<QueuedCaptureStatus> status,
      Value<int> attempts,
      Value<String?> lastFailureCode,
      Value<String?> lastFailureMessage,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> rowid,
    });

class $$QueuedCapturesTableFilterComposer
    extends Composer<_$AppDatabase, $QueuedCapturesTable> {
  $$QueuedCapturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get captureId => $composableBuilder(
    column: $table.captureId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get boxCount => $composableBuilder(
    column: $table.boxCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    QueuedCaptureStatus,
    QueuedCaptureStatus,
    String
  >
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFailureCode => $composableBuilder(
    column: $table.lastFailureCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFailureMessage => $composableBuilder(
    column: $table.lastFailureMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QueuedCapturesTableOrderingComposer
    extends Composer<_$AppDatabase, $QueuedCapturesTable> {
  $$QueuedCapturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get captureId => $composableBuilder(
    column: $table.captureId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get boxCount => $composableBuilder(
    column: $table.boxCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFailureCode => $composableBuilder(
    column: $table.lastFailureCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFailureMessage => $composableBuilder(
    column: $table.lastFailureMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QueuedCapturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueuedCapturesTable> {
  $$QueuedCapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get captureId =>
      $composableBuilder(column: $table.captureId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<int> get boxCount =>
      $composableBuilder(column: $table.boxCount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<QueuedCaptureStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastFailureCode => $composableBuilder(
    column: $table.lastFailureCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastFailureMessage => $composableBuilder(
    column: $table.lastFailureMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );
}

class $$QueuedCapturesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QueuedCapturesTable,
          QueuedCaptureRow,
          $$QueuedCapturesTableFilterComposer,
          $$QueuedCapturesTableOrderingComposer,
          $$QueuedCapturesTableAnnotationComposer,
          $$QueuedCapturesTableCreateCompanionBuilder,
          $$QueuedCapturesTableUpdateCompanionBuilder,
          (
            QueuedCaptureRow,
            BaseReferences<
              _$AppDatabase,
              $QueuedCapturesTable,
              QueuedCaptureRow
            >,
          ),
          QueuedCaptureRow,
          PrefetchHooks Function()
        > {
  $$QueuedCapturesTableTableManager(
    _$AppDatabase db,
    $QueuedCapturesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueuedCapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueuedCapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueuedCapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> captureId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<int> boxCount = const Value.absent(),
                Value<QueuedCaptureStatus> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastFailureCode = const Value.absent(),
                Value<String?> lastFailureMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedCapturesCompanion(
                captureId: captureId,
                userId: userId,
                payload: payload,
                summary: summary,
                boxCount: boxCount,
                status: status,
                attempts: attempts,
                lastFailureCode: lastFailureCode,
                lastFailureMessage: lastFailureMessage,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String captureId,
                required String userId,
                required String payload,
                required String summary,
                required int boxCount,
                required QueuedCaptureStatus status,
                Value<int> attempts = const Value.absent(),
                Value<String?> lastFailureCode = const Value.absent(),
                Value<String?> lastFailureMessage = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QueuedCapturesCompanion.insert(
                captureId: captureId,
                userId: userId,
                payload: payload,
                summary: summary,
                boxCount: boxCount,
                status: status,
                attempts: attempts,
                lastFailureCode: lastFailureCode,
                lastFailureMessage: lastFailureMessage,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QueuedCapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QueuedCapturesTable,
      QueuedCaptureRow,
      $$QueuedCapturesTableFilterComposer,
      $$QueuedCapturesTableOrderingComposer,
      $$QueuedCapturesTableAnnotationComposer,
      $$QueuedCapturesTableCreateCompanionBuilder,
      $$QueuedCapturesTableUpdateCompanionBuilder,
      (
        QueuedCaptureRow,
        BaseReferences<_$AppDatabase, $QueuedCapturesTable, QueuedCaptureRow>,
      ),
      QueuedCaptureRow,
      PrefetchHooks Function()
    >;
typedef $$BoxCodeReservationsTableCreateCompanionBuilder =
    BoxCodeReservationsCompanion Function({
      required String code,
      required String userId,
      Value<String?> centerId,
      required DateTime reservedAt,
      Value<DateTime?> spentAt,
      Value<int> rowid,
    });
typedef $$BoxCodeReservationsTableUpdateCompanionBuilder =
    BoxCodeReservationsCompanion Function({
      Value<String> code,
      Value<String> userId,
      Value<String?> centerId,
      Value<DateTime> reservedAt,
      Value<DateTime?> spentAt,
      Value<int> rowid,
    });

class $$BoxCodeReservationsTableFilterComposer
    extends Composer<_$AppDatabase, $BoxCodeReservationsTable> {
  $$BoxCodeReservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get centerId => $composableBuilder(
    column: $table.centerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reservedAt => $composableBuilder(
    column: $table.reservedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoxCodeReservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoxCodeReservationsTable> {
  $$BoxCodeReservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get centerId => $composableBuilder(
    column: $table.centerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reservedAt => $composableBuilder(
    column: $table.reservedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoxCodeReservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoxCodeReservationsTable> {
  $$BoxCodeReservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get centerId =>
      $composableBuilder(column: $table.centerId, builder: (column) => column);

  GeneratedColumn<DateTime> get reservedAt => $composableBuilder(
    column: $table.reservedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get spentAt =>
      $composableBuilder(column: $table.spentAt, builder: (column) => column);
}

class $$BoxCodeReservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoxCodeReservationsTable,
          BoxCodeReservationRow,
          $$BoxCodeReservationsTableFilterComposer,
          $$BoxCodeReservationsTableOrderingComposer,
          $$BoxCodeReservationsTableAnnotationComposer,
          $$BoxCodeReservationsTableCreateCompanionBuilder,
          $$BoxCodeReservationsTableUpdateCompanionBuilder,
          (
            BoxCodeReservationRow,
            BaseReferences<
              _$AppDatabase,
              $BoxCodeReservationsTable,
              BoxCodeReservationRow
            >,
          ),
          BoxCodeReservationRow,
          PrefetchHooks Function()
        > {
  $$BoxCodeReservationsTableTableManager(
    _$AppDatabase db,
    $BoxCodeReservationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoxCodeReservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoxCodeReservationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BoxCodeReservationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> centerId = const Value.absent(),
                Value<DateTime> reservedAt = const Value.absent(),
                Value<DateTime?> spentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoxCodeReservationsCompanion(
                code: code,
                userId: userId,
                centerId: centerId,
                reservedAt: reservedAt,
                spentAt: spentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String userId,
                Value<String?> centerId = const Value.absent(),
                required DateTime reservedAt,
                Value<DateTime?> spentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoxCodeReservationsCompanion.insert(
                code: code,
                userId: userId,
                centerId: centerId,
                reservedAt: reservedAt,
                spentAt: spentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoxCodeReservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoxCodeReservationsTable,
      BoxCodeReservationRow,
      $$BoxCodeReservationsTableFilterComposer,
      $$BoxCodeReservationsTableOrderingComposer,
      $$BoxCodeReservationsTableAnnotationComposer,
      $$BoxCodeReservationsTableCreateCompanionBuilder,
      $$BoxCodeReservationsTableUpdateCompanionBuilder,
      (
        BoxCodeReservationRow,
        BaseReferences<
          _$AppDatabase,
          $BoxCodeReservationsTable,
          BoxCodeReservationRow
        >,
      ),
      BoxCodeReservationRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductTypesTableTableManager get productTypes =>
      $$ProductTypesTableTableManager(_db, _db.productTypes);
  $$BoxesTableTableManager get boxes =>
      $$BoxesTableTableManager(_db, _db.boxes);
  $$SyncMarkersTableTableManager get syncMarkers =>
      $$SyncMarkersTableTableManager(_db, _db.syncMarkers);
  $$QueuedCapturesTableTableManager get queuedCaptures =>
      $$QueuedCapturesTableTableManager(_db, _db.queuedCaptures);
  $$BoxCodeReservationsTableTableManager get boxCodeReservations =>
      $$BoxCodeReservationsTableTableManager(_db, _db.boxCodeReservations);
}
