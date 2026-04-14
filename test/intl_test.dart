import 'package:test/test.dart';
import 'package:schedron/schedron.dart';

String fmt(String input, [Object locale = 'en']) =>
    formatSchedule(parse(input), locale);

void main() {
  group('formatSchedule', () {
    group('English (default)', () {
      test('bare day + allday', () {
        expect(fmt('mon allday'), equals('Monday, all day'));
      });

      test('day list + time range', () {
        expect(
          fmt('mon,wed,fri 09:00-17:00'),
          equals('Monday, Wednesday and Friday, 9 AM to 5 PM'),
        );
      });

      test('day range + time range', () {
        expect(
          fmt('mon-fri 08:30-12:00'),
          equals('Monday to Friday, 8:30 AM to 12 PM'),
        );
      });

      test('ordinal day', () {
        expect(fmt('1st mon 09:00-17:00'), equals('1st Monday, 9 AM to 5 PM'));
        expect(fmt('last fri 10:00-11:00'), equals('last Friday, 10 AM to 11 AM'));
      });

      test('keywords', () {
        expect(fmt('daily allday'), equals('Every day, all day'));
        expect(fmt('weekdays 09:00-17:00'), equals('Weekdays, 9 AM to 5 PM'));
        expect(fmt('weekends allday'), equals('Weekends, all day'));
      });

      test('multiple time ranges', () {
        expect(
          fmt('mon 09:00-12:00,13:00-17:00'),
          equals('Monday, 9 AM to 12 PM, 1 PM to 5 PM'),
        );
      });

      test('exceptions', () {
        expect(
          fmt('mon-fri 09:00-17:00 !wed'),
          equals('Monday to Friday, 9 AM to 5 PM (except Wednesday)'),
        );
      });

      test('multiple rules', () {
        expect(
          fmt('mon 09:00-17:00; tue 10:00-16:00'),
          equals('Monday, 9 AM to 5 PM; Tuesday, 10 AM to 4 PM'),
        );
      });

      test('time with minutes', () {
        expect(fmt('mon 09:15-17:45'), equals('Monday, 9:15 AM to 5:45 PM'));
      });

      test('time exception', () {
        expect(
          fmt('weekdays 09:00-17:00 !12:00-13:00'),
          equals('Weekdays, 9 AM to 5 PM (except 12 PM to 1 PM)'),
        );
      });

      test('day list exception', () {
        expect(
          fmt('mon-fri 09:00-17:00 !mon,wed'),
          equals('Monday to Friday, 9 AM to 5 PM (except Monday and Wednesday)'),
        );
      });
    });

    group('French', () {
      test('bare day + allday', () {
        expect(fmt('mon allday', 'fr'), equals('lundi, toute la journée'));
      });

      test('day range + time', () {
        expect(
          fmt('mon-fri 09:00-17:00', 'fr'),
          equals('lundi à vendredi, 09h00 à 17h00'),
        );
      });

      test('keyword', () {
        expect(
          fmt('weekdays 08:00-12:00', 'fr'),
          equals('Jours ouvrables, 08h00 à 12h00'),
        );
      });

      test('exceptions', () {
        expect(
          fmt('daily 09:00-17:00 !sat,sun', 'fr'),
          equals('Tous les jours, 09h00 à 17h00 (sauf samedi et dimanche)'),
        );
      });
    });

    group('German', () {
      test('bare day + allday', () {
        expect(fmt('wed allday', 'de'), equals('Mittwoch, ganztägig'));
      });

      test('day list + time', () {
        expect(
          fmt('mon,fri 10:00-14:00', 'de'),
          equals('Montag und Freitag, 10:00 bis 14:00'),
        );
      });
    });

    group('Spanish', () {
      test('keyword', () {
        expect(fmt('weekends allday', 'es'), equals('Fines de semana, todo el día'));
      });

      test('ordinal day', () {
        expect(fmt('1st mon 09:00-10:00', 'es'), equals('1º lunes, 9:00 a 10:00'));
      });
    });

    group('custom locale', () {
      test('accepts custom IntlStrings', () {
        final custom = IntlStrings(
          days: {
            DayOfWeek.mon: 'Seg',
            DayOfWeek.tue: 'Ter',
            DayOfWeek.wed: 'Qua',
            DayOfWeek.thu: 'Qui',
            DayOfWeek.fri: 'Sex',
            DayOfWeek.sat: 'Sáb',
            DayOfWeek.sun: 'Dom',
          },
          ordinals: {
            Ordinal.first: '1º',
            Ordinal.second: '2º',
            Ordinal.third: '3º',
            Ordinal.fourth: '4º',
            Ordinal.fifth: '5º',
            Ordinal.last: 'último',
          },
          keywords: {
            'daily': 'Todos os dias',
            'weekdays': 'Dias úteis',
            'weekends': 'Fins de semana',
          },
          allday: 'o dia todo',
          to: 'até',
          except: 'exceto',
          and: 'e',
          ruleSeparator: '; ',
          formatTime: (h, m) => '$h:${m.toString().padLeft(2, '0')}',
        );

        expect(
          fmt('mon-fri 09:00-18:00', custom),
          equals('Seg até Sex, 9:00 até 18:00'),
        );
      });
    });

    group('error handling', () {
      test('throws on unsupported locale', () {
        final schedule = parse('mon allday');
        expect(
          () => formatSchedule(schedule, 'zz'),
          throwsA(
            predicate((e) => e.toString().contains('Unsupported locale "zz"')),
          ),
        );
      });
    });
  });
}
