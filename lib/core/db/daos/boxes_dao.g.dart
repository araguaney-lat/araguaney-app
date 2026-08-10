// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boxes_dao.dart';

// ignore_for_file: type=lint
mixin _$BoxesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BoxesTable get boxes => attachedDatabase.boxes;
  $ProductTypesTable get productTypes => attachedDatabase.productTypes;
  BoxesDaoManager get managers => BoxesDaoManager(this);
}

class BoxesDaoManager {
  final _$BoxesDaoMixin _db;
  BoxesDaoManager(this._db);
  $$BoxesTableTableManager get boxes =>
      $$BoxesTableTableManager(_db.attachedDatabase, _db.boxes);
  $$ProductTypesTableTableManager get productTypes =>
      $$ProductTypesTableTableManager(_db.attachedDatabase, _db.productTypes);
}
