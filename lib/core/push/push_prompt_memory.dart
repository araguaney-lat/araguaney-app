import 'package:shared_preferences/shared_preferences.dart';

/// Si ya se le ofreció a esta persona activar los avisos.
///
/// Existe porque Android no lo cuenta. El sistema responde «concedido» o «no
/// concedido», y «no concedido» tapa dos situaciones que exigen lo contrario la
/// una de la otra: a quien nunca se le preguntó hay que ofrecerle, y a quien
/// dijo que no hay que dejarlo en paz. iOS sí las distingue —tiene
/// `notDetermined`—, así que esta memoria se lleva en los dos por igual y la
/// interfaz deja de depender de una diferencia entre plataformas.
///
/// No es información sensible ni de la sesión: es del dispositivo, y se va con
/// la aplicación cuando se desinstala. Por eso vive en las preferencias y no en
/// el almacén seguro ni en la base de datos, que se limpia al cambiar de
/// persona.
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
