import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/generated/models/center_out.dart';
import '../../../core/api/generated/models/user_out.dart';
import '../../../core/i18n/l10n_extension.dart';
import '../../centers/data/centers_providers.dart';
import '../../centers/data/centers_repository.dart';
import '../../team/data/team_repository.dart';
import '../data/users_providers.dart';
import '../data/users_repository.dart';
import 'invite_user_view.dart';
import 'user_record_view.dart';

/// The platform's people, beyond one centre.
///
/// **The server filters by centre, role and activity; it does not search by
/// text.** So the field at the top is not a search: it trims what has already
/// been brought, and it says so. Calling it «search» would make people believe
/// a name that does not show up does not exist, when it may be on the next
/// page.
class UsersListView extends ConsumerStatefulWidget {
  const UsersListView({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const UsersListView());

  @override
  ConsumerState<UsersListView> createState() => _UsersListViewState();
}

class _UsersListViewState extends ConsumerState<UsersListView> {
  final _filter = TextEditingController();

  String? _centerId;
  String? _centerRole;
  bool? _isActive;
  String _typed = '';

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  bool _matches(UserOut user) {
    if (_typed.isEmpty) return true;
    final needle = _typed.toLowerCase();
    return [
      user.fullName ?? '',
      user.username,
      user.email,
    ].any((field) => field.toLowerCase().contains(needle));
  }

  @override
  Widget build(BuildContext context) {
    final filter = (
      centerId: _centerId,
      centerRole: _centerRole,
      isActive: _isActive,
    );
    final users = ref.watch(usersPageProvider(filter));
    final centers = switch (ref.watch(centersProvider).valueOrNull) {
      CentersRead(:final value) => value,
      _ => const <CenterOut>[],
    };

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.usersTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(InviteUserView.route());
          ref.invalidate(usersPageProvider(filter));
        },
        icon: const Icon(Icons.person_add_alt),
        label: Text(context.l10n.userInviteTitle),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _filter,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.filter_alt_outlined),
                labelText: context.l10n.usersFilterLabel,
                helperText: context.l10n.usersFilterHelper,
              ),
              onChanged: (value) => setState(() => _typed = value.trim()),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final role in const [
                  'volunteer',
                  'coordinator',
                  'national_admin',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(centerRoleLabel(context.l10n, role)),
                      selected: _centerRole == role,
                      onSelected: (chosen) =>
                          setState(() => _centerRole = chosen ? role : null),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(context.l10n.usersOnlyInactive),
                    selected: _isActive == false,
                    onSelected: (chosen) =>
                        setState(() => _isActive = chosen ? false : null),
                  ),
                ),
                if (centers.isNotEmpty)
                  DropdownButton<String?>(
                    value: _centerId,
                    hint: Text(context.l10n.usersAnyCenter),
                    items: [
                      DropdownMenuItem(
                        child: Text(context.l10n.usersAnyCenter),
                      ),
                      for (final center in centers)
                        DropdownMenuItem(
                          value: center.id,
                          child: Text(center.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _centerId = value),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(usersPageProvider(filter)),
              child: switch (users) {
                AsyncData(value: UsersRead(:final value)) => _List(
                  users: value.where(_matches).toList(),
                  centers: {
                    for (final center in centers) center.id: center.name,
                  },
                  narrowed: _typed.isNotEmpty,
                  loaded: value.length,
                ),
                AsyncData(
                  value: UsersRefused(:final isForbidden, :final failure),
                ) =>
                  _Message(
                    isForbidden
                        ? context.l10n.usersForbidden
                        : failure.operatorMessage(context.l10n),
                  ),
                AsyncError(:final error) => _Message('$error'),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.users,
    required this.centers,
    required this.narrowed,
    required this.loaded,
  });

  final List<UserOut> users;
  final Map<String, String> centers;
  final bool narrowed;

  /// How many the page brought, before trimming. It is said because «does not
  /// show up» and «does not exist» are different things.
  final int loaded;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _Message(
        narrowed
            ? context.l10n.usersNoneMatchLoaded(loaded)
            : context.l10n.usersEmpty,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        for (final user in users)
          ListTile(
            leading: Icon(
              user.isActive ? Icons.person_outline : Icons.person_off_outlined,
            ),
            title: Text(user.fullName ?? user.username),
            subtitle: Text(
              [
                centerRoleLabel(context.l10n, user.centerRole),
                ?centers[user.centerId],
                if (!user.isActive) context.l10n.accountDisabledTag,
              ].join(' · '),
            ),
            onTap: () => Navigator.of(context).push(UserRecordView.route(user)),
          ),
        if (narrowed)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.l10n.usersNarrowedFromLoaded(loaded),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(32),
    children: [Text(text, textAlign: TextAlign.center)],
  );
}
