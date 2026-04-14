import 'types.dart';
import 'parser.dart';
import 'evaluator.dart';
import 'utils.dart';

const _maxScanDays = 400; // ~13 months, covers ordinal edge cases

/// Returns the next [DateTime] at or after [from] when [schedule] becomes active,
/// or null if no activation is found within the scan window.
/// [schedule] may be a [String] or a pre-parsed [Schedule].
DateTime? nextActivation(Object schedule, DateTime from) {
  final sched = schedule is String ? parse(schedule) : schedule as Schedule;
  if (sched.rules.isEmpty) return null;

  final fromMinute = from.hour * 60 + from.minute;
  var day = startOfDay(from);

  for (int d = 0; d < _maxScanDays; d++) {
    final intervals = getScheduleIntervalsForDate(sched, day);
    final dayStart = d == 0 ? fromMinute : 0;

    for (final iv in intervals) {
      if (iv.$2 <= dayStart) continue;
      final activationMinute = iv.$1 > dayStart ? iv.$1 : dayStart;
      final result = DateTime(
        day.year,
        day.month,
        day.day,
        activationMinute ~/ 60,
        activationMinute % 60,
      );
      if (d == 0 && activationMinute == fromMinute) {
        if (isActive(sched, result)) return result;
        continue;
      }
      return result;
    }

    day = addDays(day, 1);
  }

  return null;
}

/// Returns the next [DateTime] at or after [from] when [schedule] becomes inactive,
/// or null if the schedule is not currently active or no deactivation is found.
/// [schedule] may be a [String] or a pre-parsed [Schedule].
DateTime? nextDeactivation(Object schedule, DateTime from) {
  final sched = schedule is String ? parse(schedule) : schedule as Schedule;
  if (sched.rules.isEmpty) return null;
  if (!isActive(sched, from)) return null;

  var currentMinute = from.hour * 60 + from.minute;
  var day = startOfDay(from);

  for (int d = 0; d < _maxScanDays; d++) {
    final intervals = getScheduleIntervalsForDate(sched, day);

    int? foundEnd;
    for (final iv in intervals) {
      if (currentMinute >= iv.$1 && currentMinute < iv.$2) {
        foundEnd = iv.$2;
        break;
      }
    }

    if (foundEnd != null && foundEnd < 1440) {
      return DateTime(day.year, day.month, day.day, foundEnd ~/ 60, foundEnd % 60);
    }

    if (foundEnd != null && foundEnd >= 1440) {
      // Active until end of day — check next day
      day = addDays(day, 1);
      currentMinute = 0;
      d++;

      final nextDayStart = DateTime(day.year, day.month, day.day);
      if (!isActive(sched, nextDayStart)) return nextDayStart;
      continue;
    }

    // d > 0 and no interval contains currentMinute — just became inactive
    if (d > 0 && foundEnd == null) {
      return DateTime(
        day.year,
        day.month,
        day.day,
        currentMinute ~/ 60,
        currentMinute % 60,
      );
    }

    day = addDays(day, 1);
    currentMinute = 0;
  }

  return null;
}
