// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_dao.dart';

// ignore_for_file: type=lint
mixin _$CatalogDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductTypesTable get productTypes => attachedDatabase.productTypes;
  CatalogDaoManager get managers => CatalogDaoManager(this);
}

class CatalogDaoManager {
  final _$CatalogDaoMixin _db;
  CatalogDaoManager(this._db);
  $$ProductTypesTableTableManager get productTypes =>
      $$ProductTypesTableTableManager(_db.attachedDatabase, _db.productTypes);
}
