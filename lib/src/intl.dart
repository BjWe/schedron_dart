import 'types.dart';

/// Locale strings used to format schedules into human-readable text.
class IntlStrings {
  final Map<DayOfWeek, String> days;
  final Map<Ordinal, String> ordinals;
  final Map<String, String> keywords; // 'daily', 'weekdays', 'weekends'
  final String allday;
  final String to;
  final String except;
  final String and;
  final String ruleSeparator;
  final String Function(int hour, int minute) formatTime;

  const IntlStrings({
    required this.days,
    required this.ordinals,
    required this.keywords,
    required this.allday,
    required this.to,
    required this.except,
    required this.and,
    required this.ruleSeparator,
    required this.formatTime,
  });
}

final _en = IntlStrings(
  days: {
    DayOfWeek.mon: 'Monday',
    DayOfWeek.tue: 'Tuesday',
    DayOfWeek.wed: 'Wednesday',
    DayOfWeek.thu: 'Thursday',
    DayOfWeek.fri: 'Friday',
    DayOfWeek.sat: 'Saturday',
    DayOfWeek.sun: 'Sunday',
  },
  ordinals: {
    Ordinal.first: '1st',
    Ordinal.second: '2nd',
    Ordinal.third: '3rd',
    Ordinal.fourth: '4th',
    Ordinal.fifth: '5th',
    Ordinal.last: 'last',
  },
  keywords: {
    'daily': 'Every day',
    'weekdays': 'Weekdays',
    'weekends': 'Weekends',
  },
  allday: 'all day',
  to: 'to',
  except: 'except',
  and: 'and',
  ruleSeparator: '; ',
  formatTime: (hour, minute) {
    final period = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return minute == 0
        ? '$h $period'
        : '$h:${minute.toString().padLeft(2, '0')} $period';
  },
);

final _fr = IntlStrings(
  days: {
    DayOfWeek.mon: 'lundi',
    DayOfWeek.tue: 'mardi',
    DayOfWeek.wed: 'mercredi',
    DayOfWeek.thu: 'jeudi',
    DayOfWeek.fri: 'vendredi',
    DayOfWeek.sat: 'samedi',
    DayOfWeek.sun: 'dimanche',
  },
  ordinals: {
    Ordinal.first: '1er',
    Ordinal.second: '2e',
    Ordinal.third: '3e',
    Ordinal.fourth: '4e',
    Ordinal.fifth: '5e',
    Ordinal.last: 'dernier',
  },
  keywords: {
    'daily': 'Tous les jours',
    'weekdays': 'Jours ouvrables',
    'weekends': 'Week-ends',
  },
  allday: 'toute la journ\u00e9e',
  to: '\u00e0',
  except: 'sauf',
  and: 'et',
  ruleSeparator: ' ; ',
  formatTime: (hour, minute) =>
      '${hour.toString().padLeft(2, '0')}h'
      '${minute == 0 ? '00' : minute.toString().padLeft(2, '0')}',
);

final _de = IntlStrings(
  days: {
    DayOfWeek.mon: 'Montag',
    DayOfWeek.tue: 'Dienstag',
    DayOfWeek.wed: 'Mittwoch',
    DayOfWeek.thu: 'Donnerstag',
    DayOfWeek.fri: 'Freitag',
    DayOfWeek.sat: 'Samstag',
    DayOfWeek.sun: 'Sonntag',
  },
  ordinals: {
    Ordinal.first: '1.',
    Ordinal.second: '2.',
    Ordinal.third: '3.',
    Ordinal.fourth: '4.',
    Ordinal.fifth: '5.',
    Ordinal.last: 'letzter',
  },
  keywords: {
    'daily': 'Jeden Tag',
    'weekdays': 'Werktags',
    'weekends': 'Wochenenden',
  },
  allday: 'ganzt\u00e4gig',
  to: 'bis',
  except: 'au\u00dfer',
  and: 'und',
  ruleSeparator: '; ',
  formatTime: (hour, minute) =>
      '$hour:${minute.toString().padLeft(2, '0')}',
);

final _es = IntlStrings(
  days: {
    DayOfWeek.mon: 'lunes',
    DayOfWeek.tue: 'martes',
    DayOfWeek.wed: 'mi\u00e9rcoles',
    DayOfWeek.thu: 'jueves',
    DayOfWeek.fri: 'viernes',
    DayOfWeek.sat: 's\u00e1bado',
    DayOfWeek.sun: 'domingo',
  },
  ordinals: {
    Ordinal.first: '1\u00ba',
    Ordinal.second: '2\u00ba',
    Ordinal.third: '3\u00ba',
    Ordinal.fourth: '4\u00ba',
    Ordinal.fifth: '5\u00ba',
    Ordinal.last: '\u00faltimo',
  },
  keywords: {
    'daily': 'Todos los d\u00edas',
    'weekdays': 'D\u00edas laborables',
    'weekends': 'Fines de semana',
  },
  allday: 'todo el d\u00eda',
  to: 'a',
  except: 'excepto',
  and: 'y',
  ruleSeparator: '; ',
  formatTime: (hour, minute) =>
      '$hour:${minute.toString().padLeft(2, '0')}',
);

final _builtinLocales = {
  'en': _en,
  'fr': _fr,
  'de': _de,
  'es': _es,
};

IntlStrings _resolveStrings(Object locale) {
  if (locale is IntlStrings) return locale;
  final str = locale as String;
  final base = str.split('-')[0].toLowerCase();
  final strings = _builtinLocales[base];
  if (strings == null) {
    throw ArgumentError(
      'Unsupported locale "$locale". '
      'Use one of: ${_builtinLocales.keys.join(', ')}, '
      'or provide a custom IntlStrings instance.',
    );
  }
  return strings;
}

String _formatTimeRange(TimeRange range, IntlStrings s) {
  final start = s.formatTime(range.startHour, range.startMinute);
  final end = s.formatTime(range.endHour, range.endMinute);
  return '$start ${s.to} $end';
}

String _formatDayExpr(DayExpression expr, IntlStrings s) {
  return switch (expr) {
    BareDayExpr() => s.days[expr.day]!,
    DayListExpr() =>
      _joinList(expr.days.map((d) => s.days[d]!).toList(), s.and),
    DayRangeExpr() => '${s.days[expr.start]!} ${s.to} ${s.days[expr.end]!}',
    OrdinalDayExpr() =>
      '${s.ordinals[expr.ordinal]!} ${s.days[expr.day]!}',
    DayKeywordExpr() => s.keywords[expr.keyword]!,
  };
}

String _formatTimeExpr(TimeExpression expr, IntlStrings s) {
  return switch (expr) {
    AlldayExpr() => s.allday,
    TimeRangesExpr() =>
      expr.ranges.map((r) => _formatTimeRange(r, s)).join(', '),
  };
}

String _formatException(ExceptionExpression expr, IntlStrings s) {
  return switch (expr) {
    TimeExceptionExpression() => _formatTimeRange(expr.range, s),
    BareDayException() => s.days[expr.day]!,
    DayListException() =>
      _joinList(expr.days.map((d) => s.days[d]!).toList(), s.and),
    DayRangeException() =>
      '${s.days[expr.start]!} ${s.to} ${s.days[expr.end]!}',
    OrdinalDayException() =>
      '${s.ordinals[expr.ordinal]!} ${s.days[expr.day]!}',
  };
}

String _formatExceptions(ExceptionClause clause, IntlStrings s) {
  final parts = clause.expressions.map((e) => _formatException(e, s)).toList();
  return '${s.except} ${_joinList(parts, s.and)}';
}

String _formatRule(Rule rule, IntlStrings s) {
  final day = _formatDayExpr(rule.dayExpr, s);
  final time = _formatTimeExpr(rule.timeExpr, s);
  var result = '$day, $time';
  if (rule.exceptions != null) {
    result += ' (${_formatExceptions(rule.exceptions!, s)})';
  }
  return result;
}

String _joinList(List<String> items, String andWord) {
  if (items.isEmpty) return '';
  if (items.length == 1) return items[0];
  if (items.length == 2) return '${items[0]} $andWord ${items[1]}';
  return '${items.sublist(0, items.length - 1).join(', ')} $andWord ${items.last}';
}

/// Formats a [Schedule] into a human-readable string.
/// [locale] may be a locale string ('en', 'fr', 'de', 'es') or a custom [IntlStrings].
String formatSchedule(Schedule schedule, [Object locale = 'en']) {
  final s = _resolveStrings(locale);
  return schedule.rules.map((r) => _formatRule(r, s)).join(s.ruleSeparator);
}

/// Formats a [Schedule] into human-readable strings as array without ruleSeperator.
/// [locale] may be a locale string ('en', 'fr', 'de', 'es') or a custom [IntlStrings].
/// Useful for UI elements where you want to display each rule separately.
List<String> formatScheduleList(Schedule schedule, [Object locale = 'en']) {
  final s = _resolveStrings(locale);
  return schedule.rules.map((r) => _formatRule(r, s)).toList();
}
