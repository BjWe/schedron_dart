import 'types.dart';

const _dayMap = {
  'mon': DayOfWeek.mon,
  'tue': DayOfWeek.tue,
  'wed': DayOfWeek.wed,
  'thu': DayOfWeek.thu,
  'fri': DayOfWeek.fri,
  'sat': DayOfWeek.sat,
  'sun': DayOfWeek.sun,
};

const _ordinalMap = {
  '1st': Ordinal.first,
  '2nd': Ordinal.second,
  '3rd': Ordinal.third,
  '4th': Ordinal.fourth,
  '5th': Ordinal.fifth,
  'last': Ordinal.last,
};

const _ordinalTokens = ['1st', '2nd', '3rd', '4th', '5th', 'last'];
const _dayTokens = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _keywordTokens = ['daily', 'weekdays', 'weekends'];

/// Parses a Schedron schedule string into a [Schedule] AST.
/// Throws [ParseError] on invalid input.
Schedule parse(String input) {
  return _Parser(input.toLowerCase()).parseSchedule();
}

class _Parser {
  final String input;
  int pos = 0;

  _Parser(this.input);

  Schedule parseSchedule() {
    _skipWsp();
    if (_atEnd()) return const Schedule([]);

    final rules = [_parseRule()];

    for (;;) {
      final saved = pos;
      _skipWsp();
      if (_atEnd()) break;
      if (_tryConsume(';')) {
        _skipWsp();
        if (_atEnd()) break; // trailing semicolon
        final peek = pos;
        if (_tryConsume(';')) {
          pos = peek;
          continue;
        }
        rules.add(_parseRule());
      } else {
        pos = saved;
        break;
      }
    }

    _skipWsp();
    if (!_atEnd()) {
      _error('Expected end of input');
    }

    return Schedule(rules);
  }

  Rule _parseRule() {
    final dayExpr = _parseDayExpression();
    _requireWsp();
    final timeExpr = _parseTimeExpression();

    ExceptionClause? exceptions;
    final saved = pos;
    _skipWsp();
    if (_tryConsume('!')) {
      _skipWsp();
      exceptions = _parseExceptionClause();
    } else {
      pos = saved;
    }

    return Rule(dayExpr: dayExpr, timeExpr: timeExpr, exceptions: exceptions);
  }

  DayExpression _parseDayExpression() {
    final ordinal = _tryOrdinal();
    if (ordinal != null) {
      _requireWsp();
      final day = _consumeDay();
      return OrdinalDayExpr(ordinal, day);
    }

    final keyword = _tryKeyword();
    if (keyword != null) {
      return DayKeywordExpr(keyword);
    }

    final day = _consumeDay();

    if (_tryConsume('-')) {
      final end = _consumeDay();
      if (day == end) {
        _error(
          'Day range start and end must differ: '
          'got ${_dayTokens[day.value - 1]}-${_dayTokens[end.value - 1]}',
        );
      }
      return DayRangeExpr(day, end);
    }

    if (_tryConsume(',')) {
      final days = [day, _consumeDay()];
      while (_tryConsume(',')) {
        days.add(_consumeDay());
      }
      return DayListExpr(days.toSet().toList());
    }

    return BareDayExpr(day);
  }

  ExceptionClause _parseExceptionClause() {
    final expressions = [_parseExceptionExpression()];
    while (_tryConsume(',')) {
      expressions.add(_parseExceptionExpression());
    }
    return ExceptionClause(expressions);
  }

  ExceptionExpression _parseExceptionExpression() {
    final ordinal = _tryOrdinal();
    if (ordinal != null) {
      _requireWsp();
      final day = _consumeDay();
      return OrdinalDayException(ordinal, day);
    }

    if (_peekIsDigit()) {
      return TimeExceptionExpression(_parseTimeRange());
    }

    for (final kw in _keywordTokens) {
      if (_peekStr(kw) && !_peekIsAlpha(kw.length)) {
        _error('Day keyword "$kw" is not permitted in exception clauses');
      }
    }

    final day = _consumeDay();

    if (_tryConsume('-')) {
      final end = _consumeDay();
      if (day == end) {
        _error('Day range start and end must differ');
      }
      return DayRangeException(day, end);
    }

    if (_tryConsume(',')) {
      // pos is now past the comma
      final saved = pos;
      final nextDay = _tryDay();
      if (nextDay != null) {
        final days = [day, nextDay];
        while (_tryConsume(',')) {
          final savedInner = pos; // pos is past the comma
          final d = _tryDay();
          if (d != null) {
            days.add(d);
          } else {
            pos = savedInner - 1; // put the comma back
            break;
          }
        }
        return DayListException(days.toSet().toList());
      } else {
        pos = saved - 1; // put the comma back
        return BareDayException(day);
      }
    }

    return BareDayException(day);
  }

  TimeExpression _parseTimeExpression() {
    if (_tryConsume('allday')) {
      return AlldayExpr();
    }
    final ranges = [_parseTimeRange()];
    while (_tryConsume(',')) {
      ranges.add(_parseTimeRange());
    }
    return TimeRangesExpr(ranges);
  }

  TimeRange _parseTimeRange() {
    final startHour = _consumeHour();
    _consume(':');
    final startMinute = _consumeMinute();
    _consume('-');

    final int endHour;
    final int endMinute;
    if (_peekStr('24:00')) {
      _consume('24:00');
      endHour = 24;
      endMinute = 0;
    } else {
      endHour = _consumeHour();
      _consume(':');
      endMinute = _consumeMinute();
    }

    if (startHour == endHour && startMinute == endMinute) {
      _error('Start and end time must differ');
    }

    return TimeRange(
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
    );
  }

  // --- Token consumers ---

  DayOfWeek _consumeDay() {
    for (final token in _dayTokens) {
      if (_tryConsume(token)) return _dayMap[token]!;
    }
    _error('Expected day abbreviation (mon, tue, wed, thu, fri, sat, sun)');
  }

  DayOfWeek? _tryDay() {
    for (final token in _dayTokens) {
      if (_peekStr(token) && !_peekIsAlpha(token.length)) {
        pos += token.length;
        return _dayMap[token]!;
      }
    }
    return null;
  }

  Ordinal? _tryOrdinal() {
    for (final token in _ordinalTokens) {
      if (_peekStr(token) && !_peekIsAlpha(token.length)) {
        pos += token.length;
        return _ordinalMap[token]!;
      }
    }
    return null;
  }

  String? _tryKeyword() {
    for (final token in _keywordTokens) {
      if (_peekStr(token) && !_peekIsAlpha(token.length)) {
        pos += token.length;
        return token;
      }
    }
    return null;
  }

  int _consumeHour() {
    final d1 = _consumeDigit();
    final d2 = _consumeDigit();
    final hour = d1 * 10 + d2;
    if (hour > 23) _error('Invalid hour: $hour');
    return hour;
  }

  int _consumeMinute() {
    final d1 = _consumeDigit();
    final d2 = _consumeDigit();
    final minute = d1 * 10 + d2;
    if (minute > 59) _error('Invalid minute: $minute');
    return minute;
  }

  int _consumeDigit() {
    if (pos >= input.length) _error('Expected digit');
    final code = input.codeUnitAt(pos);
    if (code >= 48 && code <= 57) {
      // '0'-'9'
      pos++;
      return code - 48;
    }
    _error('Expected digit');
  }

  // --- Low-level helpers ---

  void _consume(String str) {
    if (!input.startsWith(str, pos)) {
      _error('Expected "$str"');
    }
    pos += str.length;
  }

  bool _tryConsume(String str) {
    if (input.startsWith(str, pos)) {
      if (str.length > 1) {
        final lastCode = str.codeUnitAt(str.length - 1);
        if (lastCode >= 97 && lastCode <= 122) {
          // last char is a-z
          if (_peekIsAlpha(str.length)) return false;
        }
      }
      pos += str.length;
      return true;
    }
    return false;
  }

  bool _peekStr(String str) => input.startsWith(str, pos);

  bool _peekIsDigit() {
    if (pos >= input.length) return false;
    final code = input.codeUnitAt(pos);
    return code >= 48 && code <= 57;
  }

  bool _peekIsAlpha([int offset = 0]) {
    final idx = pos + offset;
    if (idx >= input.length) return false;
    final code = input.codeUnitAt(idx);
    return code >= 97 && code <= 122; // 'a'-'z'
  }

  void _skipWsp() {
    while (pos < input.length) {
      final ch = input[pos];
      if (ch == ' ' || ch == '\t') {
        pos++;
      } else {
        break;
      }
    }
  }

  void _requireWsp() {
    if (pos >= input.length ||
        (input[pos] != ' ' && input[pos] != '\t')) {
      _error('Expected whitespace');
    }
    _skipWsp();
  }

  bool _atEnd() => pos >= input.length;

  Never _error(String message) {
    throw ParseError(message, pos, input);
  }
}
