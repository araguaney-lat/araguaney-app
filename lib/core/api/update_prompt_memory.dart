import 'package:shared_preferences/shared_preferences.dart';

/// How many times a version's notice was snoozed, and until when to stay quiet.
///
/// **«Más tarde» has to mean later.** If the notice came back every few hours
/// it would be dismissed by reflex, and the day the real wall arrives it would
/// arrive as a surprise after weeks of waving away the same thing. That is why
/// the silence starts long.
///
/// And it has to tighten, because a version from three days ago and one from
/// three months ago do not deserve the same insistence. The contract carries no
/// publication dates, so age is approximated by how many times **this same**
/// version has been snoozed: whoever ignores it piles up snoozes, and the
/// silence shortens with them.
///
/// The counter is stored against the specific version, so a new release starts
/// from zero: what is being asked for is a different thing.
///
/// It is neither sensitive nor session information: it belongs to the device,
/// like [PushPromptMemory], and that is why it lives in the preferences.
abstract interface class UpdatePromptMemory {
  /// Whether [version]'s notice is snoozed at [now].
  Future<bool> isSnoozed(String version, DateTime now);

  /// Snoozes [version]'s notice, counting from [now].
  Future<void> snooze(String version, DateTime now);
}

/// How long each successive snooze of the same version stays quiet.
///
/// Five days the first time, two the second, one from the third onwards. These
/// are this application's values and not those of any server control: there is
/// nothing to hide here, only a product decision written where it can be
/// argued with.
const updateSnoozeDays = [5, 2, 1];

int snoozeDaysFor(int previousSnoozes) =>
    updateSnoozeDays[previousSnoozes.clamp(0, updateSnoozeDays.length - 1)];

class PrefsUpdatePromptMemory implements UpdatePromptMemory {
  const PrefsUpdatePromptMemory();

  static const _versionKey = 'update_prompt_version';
  static const _countKey = 'update_prompt_snoozes';
  static const _untilKey = 'update_prompt_until';

  @override
  Future<bool> isSnoozed(String version, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_versionKey) != version) return false;

    final until = DateTime.tryParse(prefs.getString(_untilKey) ?? '');
    return until != null && now.isBefore(until);
  }

  @override
  Future<void> snooze(String version, DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    // A different version: the counter starts over, because what is being
    // asked for is another thing and not a repeat of the same one.
    final sameVersion = prefs.getString(_versionKey) == version;
    final previous = sameVersion ? (prefs.getInt(_countKey) ?? 0) : 0;

    await prefs.setString(_versionKey, version);
    await prefs.setInt(_countKey, previous + 1);
    await prefs.setString(
      _untilKey,
      now.add(Duration(days: snoozeDaysFor(previous))).toIso8601String(),
    );
  }
}
