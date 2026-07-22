/// Parses a database/API calendar date without applying a timezone conversion.
/// Project start/end values are dates, not instants in time.
DateTime? parseDateOnly(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value.trim());
  if (match == null) return null;
  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null || month == null || day == null) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// Serializes a calendar date as UTC midnight for OData. We construct UTC from
/// the selected calendar components instead of converting local midnight,
/// which would move Vietnamese dates to the previous day.
String dateOnlyToApi(DateTime date) {
  return DateTime.utc(date.year, date.month, date.day).toIso8601String();
}

String formatDateOnly(String? value, {String fallback = 'TBD'}) {
  final date = parseDateOnly(value);
  if (date == null) return fallback;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
