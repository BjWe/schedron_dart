import 'types.dart';

DayOfWeek dayOfWeekFromDate(DateTime date) {
  // DateTime.weekday: 1=Mon ... 7=Sun — same as DayOfWeek.value
  return DayOfWeek.fromValue(date.weekday);
}

/// Returns the day-of-month of the nth occurrence of [weekday] in [month],
/// or null if there are fewer than [n] occurrences. [month] is 1-based.
int? nthWeekdayInMonth(int year, int month, DayOfWeek weekday, int n) {
  final first = DateTime(year, month, 1);
  final firstDow = dayOfWeekFromDate(first);

  int offset = weekday.value - firstDow.value;
  if (offset < 0) offset += 7;

  final day = 1 + offset + (n - 1) * 7;
  // DateTime(year, month + 1, 0) gives the last day of month (day=0 underflows)
  final daysInMonth = DateTime(year, month + 1, 0).day;
  return day <= daysInMonth ? day : null;
}

/// Returns the day-of-month of the last occurrence of [weekday] in [month].
/// [month] is 1-based.
int lastWeekdayInMonth(int year, int month, DayOfWeek weekday) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final last = DateTime(year, month, daysInMonth);
  final lastDow = dayOfWeekFromDate(last);

  int offset = lastDow.value - weekday.value;
  if (offset < 0) offset += 7;

  return daysInMonth - offset;
}

/// Resolves an ordinal day expression to a day-of-month for the given year/month.
/// Returns null if the ordinal occurrence doesn't exist in that month.
int? resolveOrdinalDay(int year, int month, Ordinal ordinal, DayOfWeek day) {
  if (ordinal == Ordinal.last) {
    return lastWeekdayInMonth(year, month, day);
  }
  return nthWeekdayInMonth(year, month, day, ordinal.value);
}

/// Expands a day range (possibly wrapping around the week) into a list of days.
List<DayOfWeek> expandDayRange(DayOfWeek start, DayOfWeek end) {
  final days = <DayOfWeek>[];
  var current = start;
  for (;;) {
    days.add(current);
    if (current == end) break;
    current = DayOfWeek.fromValue(current.value == 7 ? 1 : current.value + 1);
  }
  return days;
}

/// Expands a day keyword into the corresponding list of days.
List<DayOfWeek> expandKeyword(String keyword) {
  switch (keyword) {
    case 'weekdays':
      return [
        DayOfWeek.mon,
        DayOfWeek.tue,
        DayOfWeek.wed,
        DayOfWeek.thu,
        DayOfWeek.fri,
      ];
    case 'weekends':
      return [DayOfWeek.sat, DayOfWeek.sun];
    case 'daily':
      return [
        DayOfWeek.mon,
        DayOfWeek.tue,
        DayOfWeek.wed,
        DayOfWeek.thu,
        DayOfWeek.fri,
        DayOfWeek.sat,
        DayOfWeek.sun,
      ];
    default:
      throw ArgumentError('Unknown keyword: $keyword');
  }
}

int timeToMinutes(int hour, int minute) => hour * 60 + minute;

(int, int) rangeToMinutes(TimeRange r) => (
      timeToMinutes(r.startHour, r.startMinute),
      timeToMinutes(r.endHour, r.endMinute),
    );

List<(int, int)> mergeIntervals(List<(int, int)> intervals) {
  if (intervals.isEmpty) return [];
  final sorted = [...intervals]
    ..sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  final merged = [sorted[0]];
  for (int i = 1; i < sorted.length; i++) {
    final last = merged.last;
    if (sorted[i].$1 <= last.$2) {
      merged[merged.length - 1] =
          (last.$1, sorted[i].$2 > last.$2 ? sorted[i].$2 : last.$2);
    } else {
      merged.add(sorted[i]);
    }
  }
  return merged;
}

List<(int, int)> subtractIntervals(
  List<(int, int)> base,
  List<(int, int)> subtract,
) {
  var result = [...base];
  for (final sub in subtract) {
    final next = <(int, int)>[];
    for (final interval in result) {
      final s = interval.$1;
      final e = interval.$2;
      if (sub.$2 <= s || sub.$1 >= e) {
        next.add((s, e));
      } else {
        if (s < sub.$1) next.add((s, sub.$1));
        if (sub.$2 < e) next.add((sub.$2, e));
      }
    }
    result = next;
  }
  return result;
}

DayOfWeek previousDay(DayOfWeek day) =>
    DayOfWeek.fromValue(day.value == 1 ? 7 : day.value - 1);

/// Adds [n] days using calendar arithmetic (DST-safe).
DateTime addDays(DateTime date, int n) => DateTime(
      date.year,
      date.month,
      date.day + n,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );

DateTime startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

int minuteOfDay(DateTime date) => date.hour * 60 + date.minute;
