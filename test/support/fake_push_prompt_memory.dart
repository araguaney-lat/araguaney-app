import 'package:araguaney_app/core/push/push_prompt_memory.dart';

/// In-memory memory of whether turning notices on was already offered.
class FakePushPromptMemory implements PushPromptMemory {
  FakePushPromptMemory({this.offered = false});

  bool offered;

  @override
  Future<bool> alreadyOffered() async => offered;

  @override
  Future<void> markOffered() async => offered = true;
}
