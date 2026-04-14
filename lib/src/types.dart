/// Core types for the Schedron scheduling language AST.

enum DayOfWeek {
  mon(1),
  tue(2),
  wed(3),
  thu(4),
  fri(5),
  sat(6),
  sun(7);

  const DayOfWeek(this.value);
  final int value;

  static DayOfWeek fromValue(int value) =>
      DayOfWeek.values.firstWhere((d) => d.value == value);
}

enum Ordinal {
  first(1),
  second(2),
  third(3),
  fourth(4),
  fifth(5),
  last(-1);

  const Ordinal(this.value);
  final int value;
}

class TimeRange {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;

  const TimeRange({
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
  });
}

// --- Day expressions ---

sealed class DayExpression {}

final class BareDayExpr extends DayExpression {
  final DayOfWeek day;
  BareDayExpr(this.day);
}

final class DayListExpr extends DayExpression {
  final List<DayOfWeek> days;
  DayListExpr(this.days);
}

final class DayRangeExpr extends DayExpression {
  final DayOfWeek start;
  final DayOfWeek end;
  DayRangeExpr(this.start, this.end);
}

final class OrdinalDayExpr extends DayExpression {
  final Ordinal ordinal;
  final DayOfWeek day;
  OrdinalDayExpr(this.ordinal, this.day);
}

final class DayKeywordExpr extends DayExpression {
  final String keyword; // 'daily' | 'weekdays' | 'weekends'
  DayKeywordExpr(this.keyword);
}

// --- Time expressions ---

sealed class TimeExpression {}

final class AlldayExpr extends TimeExpression {}

final class TimeRangesExpr extends TimeExpression {
  final List<TimeRange> ranges;
  TimeRangesExpr(this.ranges);
}

// --- Exception expressions ---

sealed class ExceptionExpression {}

final class BareDayException extends ExceptionExpression {
  final DayOfWeek day;
  BareDayException(this.day);
}

final class DayListException extends ExceptionExpression {
  final List<DayOfWeek> days;
  DayListException(this.days);
}

final class DayRangeException extends ExceptionExpression {
  final DayOfWeek start;
  final DayOfWeek end;
  DayRangeException(this.start, this.end);
}

final class OrdinalDayException extends ExceptionExpression {
  final Ordinal ordinal;
  final DayOfWeek day;
  OrdinalDayException(this.ordinal, this.day);
}

final class TimeExceptionExpression extends ExceptionExpression {
  final TimeRange range;
  TimeExceptionExpression(this.range);
}

// --- Schedule structure ---

class ExceptionClause {
  final List<ExceptionExpression> expressions;
  ExceptionClause(this.expressions);
}

class Rule {
  final DayExpression dayExpr;
  final TimeExpression timeExpr;
  final ExceptionClause? exceptions;

  Rule({
    required this.dayExpr,
    required this.timeExpr,
    this.exceptions,
  });
}

class Schedule {
  final List<Rule> rules;
  const Schedule(this.rules);
}

// --- Error ---

class ParseError implements Exception {
  final String message;
  final int position;
  final String input;

  ParseError(this.message, this.position, this.input);

  @override
  String toString() => 'ParseError: $message at position $position';
}
