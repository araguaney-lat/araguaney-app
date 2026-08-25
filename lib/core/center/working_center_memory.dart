import 'package:shared_preferences/shared_preferences.dart';

import 'working_center.dart';

/// Where the chosen centre survives a restart.
///
/// It is kept **per person**, because a centre device is shared: the shift that
/// starts at six should not inherit where the previous one was writing. That is
/// the same reasoning behind the capture queue's `user_id`, and it matters more
/// here — a working centre that carried over silently would write donations
/// into another warehouse without anybody choosing to.
///
/// It lives in the preferences and not in the secure store. It is not a secret;
/// it is a device preference, like the update reminder and the push prompt.
abstract interface class WorkingCenterMemory {
  /// The centre [userId] last chose, or null if they never did.
  Future<WorkingCenter?> read(String userId);

  Future<void> write(String userId, WorkingCenter center);
}

class PrefsWorkingCenterMemory implements WorkingCenterMemory {
  const PrefsWorkingCenterMemory();

  static String _idKey(String userId) => 'working_center_id_$userId';
  static String _nameKey(String userId) => 'working_center_name_$userId';

  @override
  Future<WorkingCenter?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_idKey(userId));
    final name = prefs.getString(_nameKey(userId));
    // Both or neither. A half-written pair would put an identifier on screen
    // where a centre name belongs, which is exactly what this type exists to
    // prevent.
    if (id == null || name == null) return null;
    return WorkingCenter(id: id, name: name);
  }

  @override
  Future<void> write(String userId, WorkingCenter center) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey(userId), center.id);
    await prefs.setString(_nameKey(userId), center.name);
  }
}

/// A memory that forgets when the process ends.
///
/// Used by tests, and it is the safe fallback if the preferences are ever
/// unavailable: the choice is asked again, which is tedious and never wrong.
class InMemoryWorkingCenterMemory implements WorkingCenterMemory {
  final _centers = <String, WorkingCenter>{};

  @override
  Future<WorkingCenter?> read(String userId) async => _centers[userId];

  @override
  Future<void> write(String userId, WorkingCenter center) async =>
      _centers[userId] = center;
}
