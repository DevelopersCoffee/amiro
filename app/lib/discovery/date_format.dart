const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "26 Sep 2026", in local time.
String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]} ${local.year}';
}
