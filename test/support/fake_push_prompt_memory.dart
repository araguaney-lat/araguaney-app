import 'package:araguaney_app/core/push/push_prompt_memory.dart';

/// Memoria en el aire de si ya se ofreció activar los avisos.
class FakePushPromptMemory implements PushPromptMemory {
  FakePushPromptMemory({this.offered = false});

  bool offered;

  @override
  Future<bool> alreadyOffered() async => offered;

  @override
  Future<void> markOffered() async => offered = true;
}
