/// Schedron: a parser and evaluator for the Schedron scheduling language.
///
/// The Schedron format is a compact, human-readable way to express recurring
/// schedules with exceptions — sitting between cron (terse, time-only) and
/// full calendar formats (verbose, event-centric).
///
/// Example schedule strings:
/// - `weekdays 09:00-17:00 !12:00-13:00`  (weekdays 9-5, no lunch)
/// - `1st mon 09:00-17:00`                (first Monday of the month)
/// - `fri 22:00-06:00`                    (Friday night into Saturday morning)
library schedron;

export 'src/types.dart';
export 'src/parser.dart' show parse;
export 'src/evaluator.dart' show isActive;
export 'src/scanner.dart' show nextActivation, nextDeactivation;
export 'src/intl.dart' show formatSchedule, formatScheduleList, IntlStrings;
