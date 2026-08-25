/// The centre a national administrator is operating in.
///
/// Everybody else has one already — the server puts it in the token and
/// ignores whatever the client sends. A national administrator belongs to no
/// centre, so every create endpoint refuses them with `CENTER_REQUIRED` until
/// one is named. This is that name, chosen once and kept.
///
/// It carries [name] and not only [id] because the point of the choice is that
/// it can be read back. An identifier on the screen is not something anybody
/// can check against the warehouse they are standing in.
class WorkingCenter {
  const WorkingCenter({required this.id, required this.name});

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is WorkingCenter && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'WorkingCenter($id, $name)';
}
