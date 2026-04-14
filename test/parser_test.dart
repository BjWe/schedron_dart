import 'package:test/test.dart';
import 'package:schedron/schedron.dart';

void main() {
  group('parser', () {
    group('empty schedule', () {
      test('parses empty string', () {
        expect(parse('').rules, isEmpty);
      });

      test('parses whitespace-only', () {
        expect(parse('   \t  ').rules, isEmpty);
      });
    });

    group('bare day', () {
      test('parses all seven days', () {
        final cases = {
          'mon': DayOfWeek.mon,
          'tue': DayOfWeek.tue,
          'wed': DayOfWeek.wed,
          'thu': DayOfWeek.thu,
          'fri': DayOfWeek.fri,
          'sat': DayOfWeek.sat,
          'sun': DayOfWeek.sun,
        };
        for (final entry in cases.entries) {
          final sched = parse('${entry.key} 09:00-17:00');
          final dayExpr = sched.rules[0].dayExpr;
          expect(dayExpr, isA<BareDayExpr>(),
              reason: '${entry.key} should parse as BareDayExpr');
          expect((dayExpr as BareDayExpr).day, equals(entry.value));
        }
      });
    });

    group('day list', () {
      test('parses two-day list', () {
        final sched = parse('mon,fri 09:00-17:00');
        final dayExpr = sched.rules[0].dayExpr as DayListExpr;
        expect(dayExpr.days, equals([DayOfWeek.mon, DayOfWeek.fri]));
      });

      test('parses three-day list', () {
        final sched = parse('mon,wed,fri 09:00-17:00');
        final dayExpr = sched.rules[0].dayExpr as DayListExpr;
        expect(dayExpr.days,
            equals([DayOfWeek.mon, DayOfWeek.wed, DayOfWeek.fri]));
      });

      test('deduplicates', () {
        final sched = parse('mon,mon,fri 09:00-17:00');
        final dayExpr = sched.rules[0].dayExpr as DayListExpr;
        expect(dayExpr.days, equals([DayOfWeek.mon, DayOfWeek.fri]));
      });

      test('rejects spaces around comma', () {
        expect(
          () => parse('mon , fri 09:00-17:00'),
          throwsA(isA<ParseError>()),
        );
      });
    });

    group('day range', () {
      test('parses forward range', () {
        final sched = parse('mon-fri 09:00-17:00');
        final dayExpr = sched.rules[0].dayExpr as DayRangeExpr;
        expect(dayExpr.start, equals(DayOfWeek.mon));
        expect(dayExpr.end, equals(DayOfWeek.fri));
      });

      test('parses wrapping range', () {
        final sched = parse('fri-mon 09:00-17:00');
        final dayExpr = sched.rules[0].dayExpr as DayRangeExpr;
        expect(dayExpr.start, equals(DayOfWeek.fri));
        expect(dayExpr.end, equals(DayOfWeek.mon));
      });

      test('rejects same-day range', () {
        expect(
          () => parse('mon-mon 09:00-17:00'),
          throwsA(isA<ParseError>()),
        );
      });

      test('rejects spaces around dash', () {
        expect(
          () => parse('mon - fri 09:00-17:00'),
          throwsA(isA<ParseError>()),
        );
      });
    });

    group('ordinal day', () {
      test('parses numbered ordinals', () {
        final cases = [
          ('1st', Ordinal.first),
          ('2nd', Ordinal.second),
          ('3rd', Ordinal.third),
          ('4th', Ordinal.fourth),
          ('5th', Ordinal.fifth),
        ];
        for (final (token, expected) in cases) {
          final sched = parse('$token mon 09:00-17:00');
          final dayExpr = sched.rules[0].dayExpr as OrdinalDayExpr;
          expect(dayExpr.ordinal, equals(expected));
          expect(dayExpr.day, equals(DayOfWeek.mon));
        }
      });

      test('parses last', () {
        final sched = parse('last fri 18:00-22:00');
        final dayExpr = sched.rules[0].dayExpr as OrdinalDayExpr;
        expect(dayExpr.ordinal, equals(Ordinal.last));
        expect(dayExpr.day, equals(DayOfWeek.fri));
      });
    });

    group('day keyword', () {
      test('parses weekdays', () {
        final sched = parse('weekdays 09:00-17:00');
        expect((sched.rules[0].dayExpr as DayKeywordExpr).keyword,
            equals('weekdays'));
      });

      test('parses weekends', () {
        final sched = parse('weekends 10:00-14:00');
        expect((sched.rules[0].dayExpr as DayKeywordExpr).keyword,
            equals('weekends'));
      });

      test('parses daily', () {
        final sched = parse('daily allday');
        expect((sched.rules[0].dayExpr as DayKeywordExpr).keyword,
            equals('daily'));
      });
    });

    group('time expression', () {
      test('parses single time range', () {
        final sched = parse('mon 09:00-17:00');
        final timeExpr = sched.rules[0].timeExpr as TimeRangesExpr;
        expect(timeExpr.ranges.length, equals(1));
        expect(timeExpr.ranges[0].startHour, equals(9));
        expect(timeExpr.ranges[0].startMinute, equals(0));
        expect(timeExpr.ranges[0].endHour, equals(17));
        expect(timeExpr.ranges[0].endMinute, equals(0));
      });

      test('parses multiple time ranges', () {
        final sched = parse('mon 09:00-12:00,13:00-17:00');
        final timeExpr = sched.rules[0].timeExpr as TimeRangesExpr;
        expect(timeExpr.ranges.length, equals(2));
        expect(timeExpr.ranges[0].startHour, equals(9));
        expect(timeExpr.ranges[0].endHour, equals(12));
        expect(timeExpr.ranges[1].startHour, equals(13));
        expect(timeExpr.ranges[1].endHour, equals(17));
      });

      test('parses allday', () {
        expect(parse('mon allday').rules[0].timeExpr, isA<AlldayExpr>());
      });

      test('parses 24:00 as end time', () {
        final sched = parse('mon 00:00-24:00');
        final timeExpr = sched.rules[0].timeExpr as TimeRangesExpr;
        expect(timeExpr.ranges[0].endHour, equals(24));
        expect(timeExpr.ranges[0].endMinute, equals(0));
      });

      test('parses overnight range', () {
        final sched = parse('fri 22:00-06:00');
        final timeExpr = sched.rules[0].timeExpr as TimeRangesExpr;
        expect(timeExpr.ranges[0].startHour, equals(22));
        expect(timeExpr.ranges[0].endHour, equals(6));
      });

      test('rejects same start and end', () {
        expect(
          () => parse('mon 09:00-09:00'),
          throwsA(isA<ParseError>()),
        );
      });

      test('rejects spaces around comma', () {
        expect(
          () => parse('mon 09:00-12:00 , 13:00-17:00'),
          throwsA(anything),
        );
      });
    });

    group('exception clause', () {
      test('parses bare day exception', () {
        final sched = parse('mon-fri 09:00-17:00 !mon');
        final ex = sched.rules[0].exceptions!.expressions[0];
        expect(ex, isA<BareDayException>());
        expect((ex as BareDayException).day, equals(DayOfWeek.mon));
      });

      test('parses ordinal exception', () {
        final sched = parse('sat 10:00-14:00 !1st sat');
        final ex = sched.rules[0].exceptions!.expressions[0] as OrdinalDayException;
        expect(ex.ordinal, equals(Ordinal.first));
        expect(ex.day, equals(DayOfWeek.sat));
      });

      test('parses day range exception', () {
        final sched = parse('mon-fri 09:00-17:00 !mon-tue');
        final ex = sched.rules[0].exceptions!.expressions[0] as DayRangeException;
        expect(ex.start, equals(DayOfWeek.mon));
        expect(ex.end, equals(DayOfWeek.tue));
      });

      test('parses time range exception', () {
        final sched = parse('weekdays 09:00-17:00 !12:00-13:00');
        final ex = sched.rules[0].exceptions!.expressions[0] as TimeExceptionExpression;
        expect(ex.range.startHour, equals(12));
        expect(ex.range.startMinute, equals(0));
        expect(ex.range.endHour, equals(13));
        expect(ex.range.endMinute, equals(0));
      });

      test('parses mixed exceptions', () {
        final sched = parse('weekdays 09:00-17:00 !12:00-13:00,1st mon');
        final exprs = sched.rules[0].exceptions!.expressions;
        expect(exprs.length, equals(2));
        expect(exprs[0], isA<TimeExceptionExpression>());
        expect(exprs[1], isA<OrdinalDayException>());
      });

      test('allows no space before !', () {
        final sched = parse('mon 09:00-17:00!tue');
        expect(sched.rules[0].exceptions, isNotNull);
      });

      test('allows space after !', () {
        final sched = parse('mon 09:00-17:00 ! tue');
        expect(sched.rules[0].exceptions, isNotNull);
      });

      test('rejects day keyword in exception', () {
        expect(
          () => parse('mon-fri 09:00-17:00 !weekdays'),
          throwsA(isA<ParseError>()),
        );
      });
    });

    group('multiple rules', () {
      test('parses semicolon-separated rules', () {
        final sched = parse('mon-fri 09:00-17:00 ; sat 10:00-13:00');
        expect(sched.rules.length, equals(2));
      });

      test('allows trailing semicolon', () {
        final sched = parse('mon 09:00-17:00 ;');
        expect(sched.rules.length, equals(1));
      });

      test('allows no space around semicolon', () {
        final sched = parse('mon 09:00-17:00;tue 09:00-17:00');
        expect(sched.rules.length, equals(2));
      });
    });

    group('case normalization', () {
      test('accepts uppercase input', () {
        final sched = parse('MON-FRI 09:00-17:00');
        final dayExpr = sched.rules[0].dayExpr as DayRangeExpr;
        expect(dayExpr.start, equals(DayOfWeek.mon));
        expect(dayExpr.end, equals(DayOfWeek.fri));
      });
    });
  });
}
