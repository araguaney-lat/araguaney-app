// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_markers_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncMarkersDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncMarkersTable get syncMarkers => attachedDatabase.syncMarkers;
  SyncMarkersDaoManager get managers => SyncMarkersDaoManager(this);
}

class SyncMarkersDaoManager {
  final _$SyncMarkersDaoMixin _db;
  SyncMarkersDaoManager(this._db);
  $$SyncMarkersTableTableManager get syncMarkers =>
      $$SyncMarkersTableTableManager(_db.attachedDatabase, _db.syncMarkers);
}
