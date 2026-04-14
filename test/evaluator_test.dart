import 'package:test/test.dart';
import 'package:schedron/schedron.dart';

// 2026-04-06 is a Monday
// 2026-04 calendar:
// Mon Tue Wed Thu Fri Sat Sun
//               1   2   3   4   5
//   6   7   8   9  10  11  12
//  13  14  15  16  17  18  19
//  20  21  22  23  24  25  26
//  27  28  29  30

void main() {
  group('isActive', () {
    group('basic day matching', () {
      test('matches bare day', () {
        expect(isActive('mon 09:00-17:00', DateTime(2026, 4, 6, 10, 0)), isTrue);
        expect(isActive('mon 09:00-17:00', DateTime(2026, 4, 7, 10, 0)), isFalse);
      });

      test('matches day range', () {
        expect(isActive('mon-fri 09:00-17:00', DateTime(2026, 4, 8, 10, 0)), isTrue); // Wed
        expect(isActive('mon-fri 09:00-17:00', DateTime(2026, 4, 11, 10, 0)), isFalse); // Sat
      });

      test('matches wrapping day range', () {
        expect(isActive('fri-mon 09:00-17:00', DateTime(2026, 4, 11, 10, 0)), isTrue); // Sat
        expect(isActive('fri-mon 09:00-17:00', DateTime(2026, 4, 8, 10, 0)), isFalse); // Wed
      });

      test('matches day list', () {
        expect(isActive('mon,wed,fri 09:00-17:00', DateTime(2026, 4, 8, 10, 0)), isTrue); // Wed
        expect(isActive('mon,wed,fri 09:00-17:00', DateTime(2026, 4, 7, 10, 0)), isFalse); // Tue
      });

      test('matches weekdays keyword', () {
        expect(isActive('weekdays 09:00-17:00', DateTime(2026, 4, 6, 10, 0)), isTrue); // Mon
        expect(isActive('weekdays 09:00-17:00', DateTime(2026, 4, 11, 10, 0)), isFalse); // Sat
      });

      test('matches weekends keyword', () {
        expect(isActive('weekends 10:00-14:00', DateTime(2026, 4, 11, 12, 0)), isTrue); // Sat
        expect(isActive('weekends 10:00-14:00', DateTime(2026, 4, 6, 12, 0)), isFalse); // Mon
      });

      test('matches daily keyword', () {
        expect(isActive('daily 09:00-17:00', DateTime(2026, 4, 6, 10, 0)), isTrue);
        expect(isActive('daily 09:00-17:00', DateTime(2026, 4, 11, 10, 0)), isTrue);
      });
    });

    group('time matching', () {
      test('matches within time range', () {
        expect(isActive('mon 09:00-17:00', DateTime(2026, 4, 6, 9, 0)), isTrue);
        expect(isActive('mon 09:00-17:00', DateTime(2026, 4, 6, 16, 59)), isTrue);
      });

      test('excludes at range end (half-open)', () {
        expect(isActive('mon 09:00-17:00', DateTime(2026, 4, 6, 17, 0)), isFalse);
      });

      test('excludes before range start', () {
        expect(isActive('mon 09:00-17:00', DateTime(2026, 4, 6, 8, 59)), isFalse);
      });

      test('matches multiple time ranges', () {
        expect(isActive('mon 09:00-12:00,13:00-17:00', DateTime(2026, 4, 6, 10, 0)), isTrue);
        expect(isActive('mon 09:00-12:00,13:00-17:00', DateTime(2026, 4, 6, 12, 30)), isFalse);
        expect(isActive('mon 09:00-12:00,13:00-17:00', DateTime(2026, 4, 6, 15, 0)), isTrue);
      });

      test('matches allday', () {
        expect(isActive('mon allday', DateTime(2026, 4, 6, 0, 0)), isTrue);
        expect(isActive('mon allday', DateTime(2026, 4, 6, 23, 59)), isTrue);
      });

      test('matches 24:00 end', () {
        expect(isActive('mon 00:00-24:00', DateTime(2026, 4, 6, 23, 59)), isTrue);
      });
    });

    group('overnight ranges', () {
      test('matches on start day after start time', () {
        expect(isActive('fri 22:00-06:00', DateTime(2026, 4, 10, 23, 0)), isTrue); // Fri 23:00
      });

      test('matches on next day before end time', () {
        expect(isActive('fri 22:00-06:00', DateTime(2026, 4, 11, 3, 0)), isTrue); // Sat 03:00
      });

      test('excludes on start day before start time', () {
        expect(isActive('fri 22:00-06:00', DateTime(2026, 4, 10, 21, 0)), isFalse); // Fri 21:00
      });

      test('excludes on next day after end time', () {
        expect(isActive('fri 22:00-06:00', DateTime(2026, 4, 11, 7, 0)), isFalse); // Sat 07:00
      });

      test('does not spill into wrong day', () {
        expect(isActive('fri 22:00-06:00', DateTime(2026, 4, 12, 3, 0)), isFalse); // Sun 03:00
      });
    });

    group('ordinal days', () {
      test('matches 1st Monday', () {
        // 2026-04-06 is the 1st Monday of April
        expect(isActive('1st mon 09:00-17:00', DateTime(2026, 4, 6, 10, 0)), isTrue);
        // 2026-04-13 is the 2nd Monday
        expect(isActive('1st mon 09:00-17:00', DateTime(2026, 4, 13, 10, 0)), isFalse);
      });

      test('matches last Friday', () {
        // 2026-04-24 is the last Friday of April
        expect(isActive('last fri 18:00-22:00', DateTime(2026, 4, 24, 20, 0)), isTrue);
        expect(isActive('last fri 18:00-22:00', DateTime(2026, 4, 17, 20, 0)), isFalse);
      });

      test('5th occurrence silently skips when nonexistent', () {
        // April 2026 has only 4 Fridays (3, 10, 17, 24)
        expect(isActive('5th fri 09:00-17:00', DateTime(2026, 4, 24, 10, 0)), isFalse);
      });

      test('5th occurrence fires when it exists', () {
        // May 2026 has 5 Fridays (1, 8, 15, 22, 29)
        expect(isActive('5th fri 09:00-17:00', DateTime(2026, 5, 29, 10, 0)), isTrue);
      });
    });

    group('day exceptions', () {
      test('excludes bare day', () {
        expect(isActive('mon-fri 09:00-17:00 !wed', DateTime(2026, 4, 8, 10, 0)), isFalse); // Wed
        expect(isActive('mon-fri 09:00-17:00 !wed', DateTime(2026, 4, 7, 10, 0)), isTrue); // Tue
      });

      test('excludes day range', () {
        expect(isActive('mon-fri 09:00-17:00 !mon-tue', DateTime(2026, 4, 6, 10, 0)), isFalse); // Mon
        expect(isActive('mon-fri 09:00-17:00 !mon-tue', DateTime(2026, 4, 8, 10, 0)), isTrue); // Wed
      });

      test('excludes ordinal day', () {
        expect(isActive('sat 10:00-14:00 !1st sat', DateTime(2026, 4, 4, 12, 0)), isFalse); // 1st Sat
        expect(isActive('sat 10:00-14:00 !1st sat', DateTime(2026, 4, 11, 12, 0)), isTrue); // 2nd Sat
      });

      test('exception does not affect other rules (union)', () {
        expect(
          isActive(
            'mon 09:00-17:00 ; mon-fri 10:00-11:00 !mon',
            DateTime(2026, 4, 6, 10, 30),
          ),
          isTrue, // Mon — rule 1 still fires even though rule 2 excepts Mon
        );
      });
    });

    group('time exceptions', () {
      test('subtracts time window', () {
        expect(isActive('weekdays 09:00-17:00 !12:00-13:00', DateTime(2026, 4, 6, 12, 30)), isFalse);
        expect(isActive('weekdays 09:00-17:00 !12:00-13:00', DateTime(2026, 4, 6, 10, 0)), isTrue);
        expect(isActive('weekdays 09:00-17:00 !12:00-13:00', DateTime(2026, 4, 6, 13, 0)), isTrue);
      });

      test('overnight time exception wraps', () {
        expect(isActive('daily 00:00-24:00 !23:00-01:00', DateTime(2026, 4, 6, 23, 30)), isFalse);
        expect(isActive('daily 00:00-24:00 !23:00-01:00', DateTime(2026, 4, 6, 0, 30)), isFalse);
        expect(isActive('daily 00:00-24:00 !23:00-01:00', DateTime(2026, 4, 6, 1, 0)), isTrue);
      });
    });

    group('mixed exceptions', () {
      test('excludes both day and time', () {
        const sched = 'weekdays 09:00-17:00 !12:00-13:00,1st mon';
        // 1st Monday — fully excluded
        expect(isActive(sched, DateTime(2026, 4, 6, 10, 0)), isFalse);
        // Tuesday at lunch — time excepted
        expect(isActive(sched, DateTime(2026, 4, 7, 12, 30)), isFalse);
        // Tuesday morning — active
        expect(isActive(sched, DateTime(2026, 4, 7, 10, 0)), isTrue);
      });
    });

    group('fully cancelled rules', () {
      test('never fires when all days excepted', () {
        expect(isActive('mon 09:00-17:00 !mon', DateTime(2026, 4, 6, 10, 0)), isFalse);
      });

      test('never fires when all time excepted', () {
        expect(isActive('mon 09:00-17:00 !09:00-17:00', DateTime(2026, 4, 6, 10, 0)), isFalse);
      });
    });

    group('empty schedule', () {
      test('never fires', () {
        expect(isActive('', DateTime(2026, 4, 6, 10, 0)), isFalse);
      });
    });

    group('multiple rules (union)', () {
      test('unions rules', () {
        const sched = 'mon-fri 09:00-17:00 ; sat 10:00-13:00';
        expect(isActive(sched, DateTime(2026, 4, 6, 10, 0)), isTrue); // Mon
        expect(isActive(sched, DateTime(2026, 4, 11, 11, 0)), isTrue); // Sat
        expect(isActive(sched, DateTime(2026, 4, 12, 11, 0)), isFalse); // Sun
      });
    });
  });
}
