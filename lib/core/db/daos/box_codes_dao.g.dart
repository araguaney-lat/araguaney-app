// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'box_codes_dao.dart';

// ignore_for_file: type=lint
mixin _$BoxCodesDaoMixin on DatabaseAccessor<AppDatabase> {
  $BoxCodeReservationsTable get boxCodeReservations =>
      attachedDatabase.boxCodeReservations;
  BoxCodesDaoManager get managers => BoxCodesDaoManager(this);
}

class BoxCodesDaoManager {
  final _$BoxCodesDaoMixin _db;
  BoxCodesDaoManager(this._db);
  $$BoxCodeReservationsTableTableManager get boxCodeReservations =>
      $$BoxCodeReservationsTableTableManager(
        _db.attachedDatabase,
        _db.boxCodeReservations,
      );
}
