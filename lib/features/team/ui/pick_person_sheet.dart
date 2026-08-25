import 'package:flutter/material.dart';

import '../../../core/api/generated/models/user_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../data/team_repository.dart';

/// Elegir a quién sumar a una campaña, de entre el equipo del centro.
///
/// La lista llega ya filtrada: solo cuentas activas que todavía no participan.
/// Ofrecer a alguien que ya está dentro haría trabajar al servidor para no
/// cambiar nada.
class PickPersonSheet extends StatelessWidget {
  const PickPersonSheet({super.key, required this.people});

  final List<UserOut> people;

  static Future<UserOut?> show(
    BuildContext context, {
    required List<UserOut> people,
  }) => showModalBottomSheet<UserOut>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => PickPersonSheet(people: people),
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: people.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              context.l10n.noOneLeftToAdd,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        : ListView.separated(
            shrinkWrap: true,
            itemCount: people.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    context.l10n.addToCampaignTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              }
              final person = people[index - 1];
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(person.fullName ?? person.username),
                subtitle: Text(
                  '${centerRoleLabel(person.centerRole)} · ${person.username}',
                ),
                onTap: () => Navigator.of(context).pop(person),
              );
            },
          ),
  );
}
