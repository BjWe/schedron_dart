import 'package:test/test.dart';
import 'package:schedron/schedron.dart';

void main() {
  group('nextActivation', () {
    test('returns null for empty schedule', () {
      expect(nextActivation('', DateTime(2026, 4, 6, 10, 0)), isNull);
    });

    test('finds activation on same day', () {
      final result = nextActivation('mon 09:00-17:00', DateTime(2026, 4, 6, 8, 0));
      expect(result, equals(DateTime(2026, 4, 6, 9, 0)));
    });

    test('finds activation on next matching day', () {
      // Tuesday — next Monday is April 13
      final result = nextActivation('mon 09:00-17:00', DateTime(2026, 4, 7, 18, 0));
      expect(result, equals(DateTime(2026, 4, 13, 9, 0)));
    });

    test('returns current time if already active', () {
      final result = nextActivation('mon 09:00-17:00', DateTime(2026, 4, 6, 10, 0));
      expect(result, equals(DateTime(2026, 4, 6, 10, 0)));
    });

    test('finds next time range on same day', () {
      final result = nextActivation(
        'mon 09:00-12:00,14:00-17:00',
        DateTime(2026, 4, 6, 13, 0),
      );
      expect(result, equals(DateTime(2026, 4, 6, 14, 0)));
    });

    test('finds activation for ordinal day', () {
      // From April 7 (Tue), next 1st Mon is May 4
      final result = nextActivation(
        '1st mon 09:00-17:00',
        DateTime(2026, 4, 7, 10, 0),
      );
      expect(result, equals(DateTime(2026, 5, 4, 9, 0)));
    });
  });

  group('nextDeactivation', () {
    test('returns null when not active', () {
      expect(
        nextDeactivation('mon 09:00-17:00', DateTime(2026, 4, 6, 8, 0)),
        isNull,
      );
    });

    test('returns null for empty schedule', () {
      expect(nextDeactivation('', DateTime(2026, 4, 6, 10, 0)), isNull);
    });

    test('finds end of current time range', () {
      final result = nextDeactivation('mon 09:00-17:00', DateTime(2026, 4, 6, 10, 0));
      expect(result, equals(DateTime(2026, 4, 6, 17, 0)));
    });

    test('finds deactivation for allday (daily allday is always active)', () {
      // daily allday — active all day every day, never deactivates within scan window
      final result = nextDeactivation('daily allday', DateTime(2026, 4, 6, 10, 0));
      expect(result, isNull);
    });

    test('finds deactivation across overnight', () {
      final result = nextDeactivation('fri 22:00-06:00', DateTime(2026, 4, 10, 23, 0));
      expect(result, equals(DateTime(2026, 4, 11, 6, 0)));
    });
  });
}
