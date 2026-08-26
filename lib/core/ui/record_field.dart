import 'package:flutter/material.dart';

/// One line of a record: label above, value below.
///
/// It lives in `core` because several read-only records use it, and a box
/// should look the same whether it comes from the cache or from a scan.
class RecordField extends StatelessWidget {
  const RecordField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    title: Text(label, style: Theme.of(context).textTheme.labelMedium),
    subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
  );
}

/// A short date in the order the region reads it.
///
/// `intl` would format the same thing in exchange for dragging localisation
/// into read-only screens that need it for nothing else.
String formatShortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

/// The same date with the time, for what happened during one particular shift.
///
/// A capture queued this morning and one from the day before yesterday are told
/// apart by the day; two from the same morning, only by the time.
String formatShortDateTime(DateTime at) =>
    '${formatShortDate(at)} ${at.hour.toString().padLeft(2, '0')}:'
    '${at.minute.toString().padLeft(2, '0')}';
