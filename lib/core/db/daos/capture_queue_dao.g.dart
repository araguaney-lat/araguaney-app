// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capture_queue_dao.dart';

// ignore_for_file: type=lint
mixin _$CaptureQueueDaoMixin on DatabaseAccessor<AppDatabase> {
  $QueuedCapturesTable get queuedCaptures => attachedDatabase.queuedCaptures;
  CaptureQueueDaoManager get managers => CaptureQueueDaoManager(this);
}

class CaptureQueueDaoManager {
  final _$CaptureQueueDaoMixin _db;
  CaptureQueueDaoManager(this._db);
  $$QueuedCapturesTableTableManager get queuedCaptures =>
      $$QueuedCapturesTableTableManager(
        _db.attachedDatabase,
        _db.queuedCaptures,
      );
}
