import 'types.dart';
import 'utils.dart';
import 'parser.dart';

/// Returns true if [schedule] is active at [datetime].
/// [schedule] may be a [String] (parsed on the fly) or a pre-parsed [Schedule].
bool isActive(Object schedule, DateTime datetime) {
  final sched = schedule is String ? parse(schedule) : schedule as Schedule;
  return sched.rules.any((rule) => _ruleIsActive(rule, datetime));
}

bool _ruleIsActive(Rule rule, DateTime datetime) {
  final dow = dayOfWeekFromDate(datetime);
  final minute = minuteOfDay(datetime);
  final year = datetime.year;
  final month = datetime.month;
  final dayOfMonth = datetime.day;

  final intervals =
      _getActiveIntervalsForDate(rule, year, month, dayOfMonth, dow);
  return intervals.any((iv) => minute >= iv.$1 && minute < iv.$2);
}

List<(int, int)> _getActiveIntervalsForDate(
  Rule rule,
  int year,
  int month,
  int dayOfMonth,
  DayOfWeek dow,
) {
  final allIntervals = <(int, int)>[];

  // Direct match: today's day matches the rule's day expression
  if (_dayMatchesExpression(rule.dayExpr, year, month, dayOfMonth, dow)) {
    if (!_isDayExcepted(rule.exceptions, year, month, dayOfMonth, dow)) {
      for (final iv in _resolveTimeIntervals(rule.timeExpr)) {
        if (iv.$1 < iv.$2) {
          allIntervals.add(iv); // normal range
        } else {
          allIntervals.add((iv.$1, 1440)); // overnight: today's portion
        }
      }
    }
  }

  // Overnight spillover: check if yesterday matched and has a wrapping range
  final yesterday = DateTime(year, month, dayOfMonth - 1);
  final yDow = dayOfWeekFromDate(yesterday);
  final yYear = yesterday.year;
  final yMonth = yesterday.month;
  final yDom = yesterday.day;

  if (_dayMatchesExpression(rule.dayExpr, yYear, yMonth, yDom, yDow)) {
    if (!_isDayExcepted(rule.exceptions, yYear, yMonth, yDom, yDow)) {
      for (final iv in _resolveTimeIntervals(rule.timeExpr)) {
        if (iv.$1 >= iv.$2 && iv.$2 > 0) {
          allIntervals.add((0, iv.$2)); // overnight: next-day portion
        }
      }
    }
  }

  var merged = mergeIntervals(allIntervals);
  if (rule.exceptions != null) {
    merged =
        subtractIntervals(merged, _getTimeExceptionIntervals(rule.exceptions!));
  }
  return merged;
}

bool _dayMatchesExpression(
  DayExpression expr,
  int year,
  int month,
  int dayOfMonth,
  DayOfWeek dow,
) {
  return switch (expr) {
    BareDayExpr() => dow == expr.day,
    DayListExpr() => expr.days.contains(dow),
    DayRangeExpr() => expandDayRange(expr.start, expr.end).contains(dow),
    DayKeywordExpr() => expandKeyword(expr.keyword).contains(dow),
    OrdinalDayExpr() =>
      resolveOrdinalDay(year, month, expr.ordinal, expr.day) == dayOfMonth,
  };
}

bool _isDayExcepted(
  ExceptionClause? exceptions,
  int year,
  int month,
  int dayOfMonth,
  DayOfWeek dow,
) {
  if (exceptions == null) return false;
  return exceptions.expressions
      .any((ex) => _dayExceptionMatches(ex, year, month, dayOfMonth, dow));
}

bool _dayExceptionMatches(
  ExceptionExpression ex,
  int year,
  int month,
  int dayOfMonth,
  DayOfWeek dow,
) {
  return switch (ex) {
    BareDayException() => dow == ex.day,
    DayListException() => ex.days.contains(dow),
    DayRangeException() => expandDayRange(ex.start, ex.end).contains(dow),
    OrdinalDayException() =>
      resolveOrdinalDay(year, month, ex.ordinal, ex.day) == dayOfMonth,
    TimeExceptionExpression() => false, // time exceptions don't exclude days
  };
}

List<(int, int)> _resolveTimeIntervals(TimeExpression timeExpr) {
  return switch (timeExpr) {
    AlldayExpr() => [(0, 1440)],
    TimeRangesExpr() => timeExpr.ranges.map(rangeToMinutes).toList(),
  };
}

List<(int, int)> _getTimeExceptionIntervals(ExceptionClause exceptions) {
  final intervals = <(int, int)>[];
  for (final ex in exceptions.expressions) {
    if (ex is TimeExceptionExpression) {
      final iv = rangeToMinutes(ex.range);
      if (iv.$1 < iv.$2) {
        intervals.add(iv);
      } else {
        // Overnight time exception wraps
        intervals.add((iv.$1, 1440));
        intervals.add((0, iv.$2));
      }
    }
  }
  return mergeIntervals(intervals);
}

/// Returns the merged active intervals for [date] across all rules in [sched].
/// Used by the scanner for efficient forward iteration.
List<(int, int)> getScheduleIntervalsForDate(Schedule sched, DateTime date) {
  final dow = dayOfWeekFromDate(date);
  final year = date.year;
  final month = date.month;
  final dayOfMonth = date.day;

  final all = <(int, int)>[];
  for (final rule in sched.rules) {
    all.addAll(_getActiveIntervalsForDate(rule, year, month, dayOfMonth, dow));
  }
  return mergeIntervals(all);
}
