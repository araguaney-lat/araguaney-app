import 'package:flutter/material.dart';

import '../../../core/ui/sheet_insets.dart';

/// Lo que hace falta para dar de alta a alguien en el centro.
typedef InviteDraft = ({
  String email,
  String username,
  String? fullName,
  String centerRole,
});

/// Alta de una persona en el propio centro.
///
/// El centro no se elige: es el de quien tiene la sesión, y el servidor
/// rechaza cualquier otro. El rol tampoco ofrece administración nacional,
/// porque el backend no deja crearla desde aquí.
class InvitePersonSheet extends StatefulWidget {
  const InvitePersonSheet({super.key});

  static Future<InviteDraft?> show(BuildContext context) =>
      showModalBottomSheet<InviteDraft>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => const InvitePersonSheet(),
      );

  @override
  State<InvitePersonSheet> createState() => _InvitePersonSheetState();
}

class _InvitePersonSheetState extends State<InvitePersonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  String _role = 'volunteer';

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    _fullName.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final fullName = _fullName.text.trim();
    Navigator.of(context).pop((
      email: _email.text.trim(),
      username: _username.text.trim(),
      fullName: fullName.isEmpty ? null : fullName,
      centerRole: _role,
    ));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      left: 16,
      right: 16,
      top: 16,
      bottom: sheetBottomInset(context),
    ),
    child: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sumar a alguien al centro',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Recibirá un correo con su acceso. La contraseña la genera el '
            'servidor y no se ve desde aquí.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Correo'),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Escribe el correo';
              // Comprobación mínima: quien valida de verdad es el servidor, y
              // una expresión regular más lista rechazaría correos válidos.
              return text.contains('@') ? null : 'Ese correo no parece válido';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _username,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Nombre de usuario'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Escribe el nombre de usuario'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fullName,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre y apellido (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Rol'),
            items: const [
              DropdownMenuItem(value: 'volunteer', child: Text('Voluntariado')),
              DropdownMenuItem(
                value: 'coordinator',
                child: Text('Coordinación'),
              ),
            ],
            onChanged: (value) => setState(() => _role = value ?? 'volunteer'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Enviar invitación'),
            ),
          ),
        ],
      ),
    ),
  );
}
