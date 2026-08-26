import 'package:shared_preferences/shared_preferences.dart';

/// Whether this person has already been offered to turn notices on.
///
/// It exists because Android does not say. The system answers «concedido» or
/// «no concedido», and «no concedido» covers two situations that call for
/// opposite things: somebody who was never asked should be offered, and
/// somebody who said no should be left alone. iOS does tell them apart — it has
/// `notDetermined` — so this memory is kept on both alike and the interface
/// stops depending on a difference between platforms.
///
/// It is neither sensitive nor session information: it belongs to the device,
/// and it goes with the application when it is uninstalled. That is why it
/// lives in the preferences and not in secure storage or in the database, which
/// is wiped when the person changes.
abstract interface class PushPromptMemory {
  Future<bool> alreadyOffered();

  Future<void> markOffered();
}

class PrefsPushPromptMemory implements PushPromptMemory {
  const PrefsPushPromptMemory();

  static const _key = 'push_prompt_offered';

  @override
  Future<bool> alreadyOffered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  @override
  Future<void> markOffered() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
