import 'package:araguaney_app/core/api/update_prompt_memory.dart';

/// Memoria de aplazamientos en el aire, que además apunta lo que le pidieron.
class FakeUpdatePromptMemory implements UpdatePromptMemory {
  FakeUpdatePromptMemory({this.snoozed = false});

  bool snoozed;
  final List<String> snoozedVersions = [];

  @override
  Future<bool> isSnoozed(String version, DateTime now) async => snoozed;

  @override
  Future<void> snooze(String version, DateTime now) async {
    snoozed = true;
    snoozedVersions.add(version);
  }
}
