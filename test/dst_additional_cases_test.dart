// Additional DST regression coverage beyond test/dst_and_edge_cases_test.dart,
// which only exercises the 2026 SPRING-FORWARD transition (2026-03-29,
// clocks jump 00:00 -> 01:00, losing an hour). This file covers:
//
//   1. The AUTUMN FALL-BACK transition (2026-10-25 for Europe/Lisbon, clocks
//      go back 01:00 -> 00:00, an hour repeats) -- a different direction of
//      drift that a fix tuned only against spring-forward could plausibly
//      miss (e.g. an off-by-one in a guard that assumes the drift is always
//      "+1 hour").
//   2. A different year's spring-forward (2027-03-28) and fall-back
//      (2027-10-31), to make sure the fix generalizes and isn't accidentally
//      only correct for the specific dates hardcoded across the 2026 tests.
//
// (Portugal's DST rule -- last Sunday of March / October -- is set by EU
// directive and has been stable for decades; there is no cross-year rule
// change to worry about here, but re-running the same style of check on a
// different year is still useful as a check against date literals that were
// coincidentally correct only for 2026.)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/services/schedule_logic.dart';

Client _weeklyClient({
  required int weekday,
  required DateTime startDate,
  String frequency = 'Semanal',
  PaymentType paymentType = PaymentType.mensal,
}) {
  return Client(
    id: 'c1',
    activityType: ActivityType.education,
    name: 'Aluno Teste',
    contactEmail: '',
    contactPhone: '',
    notes: '',
    serviceType: 'Matematica',
    sessionFrequency: frequency,
    slots: [WeeklySlot(weekday: weekday, time: const TimeOfDay(hour: 18, minute: 0))],
    sessionDurationMinutes: 60,
    startDate: startDate,
    endDate: null,
    paymentType: paymentType,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
  );
}

void main() {
  group('Confirm the exact Europe/Lisbon DST boundaries this machine uses (sanity)', () {
    test('2026 fall-back is 2026-10-25 (WEST -> WET, clocks go back)', () {
      expect(DateTime(2026, 10, 24, 12).timeZoneOffset, const Duration(hours: 1));
      expect(DateTime(2026, 10, 25, 12).timeZoneOffset, Duration.zero);
    });

    test('2027 spring-forward is 2027-03-28 and fall-back is 2027-10-31', () {
      expect(DateTime(2027, 3, 27, 12).timeZoneOffset, Duration.zero);
      expect(DateTime(2027, 3, 28, 12).timeZoneOffset, const Duration(hours: 1));
      expect(DateTime(2027, 10, 30, 12).timeZoneOffset, const Duration(hours: 1));
      expect(DateTime(2027, 10, 31, 12).timeZoneOffset, Duration.zero);
    });
  });

  group('Autumn fall-back (2026-10-25) — addCalendarDays / calendarDaysBetween stay correct', () {
    test('sanity: raw Duration(days:1) stepping drifts the OTHER way (backwards into '
        '23:00 the previous day) across fall-back, confirming this is a real two-directional '
        'risk, not just a spring-forward one', () {
      var cursor = DateTime(2026, 10, 22); // Thursday, midnight, before the transition.
      for (var i = 0; i < 5; i++) {
        cursor = cursor.add(const Duration(days: 1));
      }
      // By 2026-10-27 naive "+1 day" stepping has drifted to 23:00 on 10-26 instead
      // of staying at midnight on 10-27, because of the fall-back on 10-25.
      expect(cursor, isNot(DateTime(2026, 10, 27)));
      expect(cursor.hour, isNot(0));
    });

    test('generateOccurrencesInRange produces the correct weekly Sunday occurrences '
        'spanning the 2026-10-25 fall-back, with no dropped or duplicated day', () {
      final client = _weeklyClient(weekday: DateTime.sunday, startDate: DateTime(2025, 1, 5));

      final occurrences = generateOccurrencesInRange(
        client,
        rangeStart: DateTime(2026, 10, 18),
        rangeEnd: DateTime(2026, 11, 8),
      );
      final dates = occurrences.map((d) => DateTime(d.year, d.month, d.day)).toList();

      expect(dates, [
        DateTime(2026, 10, 18),
        DateTime(2026, 10, 25), // the fall-back day itself
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 8),
      ]);
    });

    test('Quinzenal (biweekly) parity survives the fall-back transition', () {
      final client = _weeklyClient(
        weekday: DateTime.wednesday,
        startDate: DateTime(2026, 10, 7), // a Wednesday
        frequency: 'Quinzenal',
      );

      final occurrences = generateOccurrencesInRange(
        client,
        rangeStart: DateTime(2026, 10, 1),
        rangeEnd: DateTime(2026, 12, 31),
      );
      final dates = occurrences.map((d) => DateTime(d.year, d.month, d.day)).toList();

      expect(dates, [
        DateTime(2026, 10, 7),
        DateTime(2026, 10, 21),
        DateTime(2026, 11, 4),
        DateTime(2026, 11, 18),
        DateTime(2026, 12, 2),
        DateTime(2026, 12, 16),
        DateTime(2026, 12, 30),
      ]);
    });

    test('monthly payment cycle correctly closes on the last Sunday of October 2026 '
        '(the 25th, which is also the fall-back day itself)', () {
      final client = _weeklyClient(weekday: DateTime.sunday, startDate: DateTime(2025, 1, 5));
      int idc = 0;
      SessionRecord session(DateTime d) {
        idc++;
        return SessionRecord(id: 's$idc', clientId: 'c1', registeredAt: d, scheduledFor: d, durationMinutes: 60, amount: 20);
      }

      final sessions = [
        session(DateTime(2026, 10, 4, 18, 0)),
        session(DateTime(2026, 10, 25, 18, 0)), // last Sunday of October, and the fall-back day
      ];

      final group = computePaymentCycles(client, sessions).single;
      expect(group.periodEnd, DateTime(2026, 10, 25, 23, 59, 59, 999));
      expect(group.isClosed(DateTime(2026, 10, 25, 23, 59, 59)), isFalse);
      expect(group.isClosed(DateTime(2026, 10, 26, 0, 0, 1)), isTrue);
    });
  });

  group('A different year (2027) — spring-forward and fall-back both still handled '
      'correctly, confirming the fix is not accidentally 2026-specific', () {
    test('weekly occurrences span the 2027-03-28 spring-forward correctly', () {
      final client = _weeklyClient(weekday: DateTime.friday, startDate: DateTime(2026, 1, 2));

      final occurrences = generateOccurrencesInRange(
        client,
        rangeStart: DateTime(2027, 3, 22),
        rangeEnd: DateTime(2027, 4, 5),
      );
      final dates = occurrences.map((d) => DateTime(d.year, d.month, d.day)).toList();

      expect(dates, [
        DateTime(2027, 3, 26),
        DateTime(2027, 4, 2),
      ]);
    });

    test('weekly occurrences span the 2027-10-31 fall-back correctly', () {
      final client = _weeklyClient(weekday: DateTime.sunday, startDate: DateTime(2026, 1, 4));

      final occurrences = generateOccurrencesInRange(
        client,
        rangeStart: DateTime(2027, 10, 25),
        rangeEnd: DateTime(2027, 11, 8),
      );
      final dates = occurrences.map((d) => DateTime(d.year, d.month, d.day)).toList();

      expect(dates, [
        DateTime(2027, 10, 31),
        DateTime(2027, 11, 7),
      ]);
    });

    test('monthly payment cycle closes correctly on the last Tuesday of a month '
        'containing the 2027-10-31 fall-back', () {
      // 2027-10-26 is a Tuesday and the last Tuesday of October 2027.
      final client = _weeklyClient(weekday: DateTime.tuesday, startDate: DateTime(2026, 1, 6));
      expect(DateTime(2027, 10, 26).weekday, DateTime.tuesday);

      int idc = 0;
      SessionRecord session(DateTime d) {
        idc++;
        return SessionRecord(id: 's$idc', clientId: 'c1', registeredAt: d, scheduledFor: d, durationMinutes: 60, amount: 20);
      }

      final sessions = [session(DateTime(2027, 10, 26, 18, 0))];
      final group = computePaymentCycles(client, sessions).single;
      expect(group.periodEnd, DateTime(2027, 10, 26, 23, 59, 59, 999));
    });
  });
}
