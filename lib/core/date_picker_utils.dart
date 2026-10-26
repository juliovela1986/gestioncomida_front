class SafeDatePickerConfig {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const SafeDatePickerConfig({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });
}

DateTime normalizeToDateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

SafeDatePickerConfig buildSafeDatePickerConfig({
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  var safeFirstDate = normalizeToDateOnly(firstDate);
  var safeLastDate = normalizeToDateOnly(lastDate);

  if (safeFirstDate.isAfter(safeLastDate)) {
    safeFirstDate = safeLastDate;
  }

  final normalizedInitialDate = normalizeToDateOnly(initialDate ?? safeFirstDate);
  final safeInitialDate = normalizedInitialDate.isBefore(safeFirstDate)
      ? safeFirstDate
      : normalizedInitialDate.isAfter(safeLastDate)
          ? safeLastDate
          : normalizedInitialDate;

  return SafeDatePickerConfig(
    initialDate: safeInitialDate,
    firstDate: safeFirstDate,
    lastDate: safeLastDate,
  );
}

