// Tests for the "reschedule/cancel a single occurrence" feature:
// OccurrenceOverride (models.dart), generateResolvedOccurrencesInRange,
// upsertOverride/removeOverrideForDay (schedule_logic.dart), and their
// interaction with computePaymentCycles/upcomingThisWeek/registerableNow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/services/schedule_logic.dart';

Client _weeklyClient({
  required int weekday,
  required DateTime startDate,
  String frequency = 'Semanal',
  List<OccurrenceOverride> occurrenceOverrides = const [],
}) {
  return Client(
    id: 'c1',
    activityType: ActivityType.education,
    name: 'Aluno Teste',
    contactEmail: '',
    contactPhone: '',
    notes: '',
    serviceType: 'Matemática',
    sessionFrequency: frequency,
    slots: [WeeklySlot(weekday: weekday, time: const TimeOfDay(hour: 18, minute: 0))],
    sessionDurationMinutes: 60,
    startDate: startDate,
    endDate: null,
    paymentType: PaymentType.mensal,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
    occurrenceOverrides: occurrenceOverrides,
  );
}

int _idCounter = 0;
SessionRecord _session(DateTime scheduledFor) {
  _idCounter++;
  return SessionRecord(
    id: 's$_idCounter',
    clientId: 'c1',
    registeredAt: scheduledFor,
    scheduledFor: scheduledFor,
    durationMinutes: 60,
    amount: 20,
  );
}

void main() {
  group('generateResolvedOccurrencesInRange — moved occurrence', () {
    test('appears at the new date/time and is absent at the original date', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        occurrenceOverrides: [
          OccurrenceOverride(
            originalScheduledFor: DateTime(2026, 1, 12, 18, 0),
            newDateTime: DateTime(2026, 1, 14, 20, 0), // Monday -> Wednesday, same week
          ),
        ],
      );

      final resolved = generateResolvedOccurrencesInRange(
        client,
        rangeStart: DateTime(2026, 1, 1),
        rangeEnd: DateTime(2026, 1, 31),
      );
      final scheduledDates = resolved.map((r) => r.scheduledFor).toList();

      expect(scheduledDates, contains(DateTime(2026, 1, 14, 20, 0)));
      expect(scheduledDates, isNot(contains(DateTime(2026, 1, 12, 18, 0))));
      // The other Mondays (5, 19, 26) are untouched.
      expect(scheduledDates, containsAll([DateTime(2026, 1, 5, 18, 0), DateTime(2026, 1, 19, 18, 0), DateTime(2026, 1, 26, 18, 0)]));
    });

    test('the resolved occurrence carries both the new and the original date/time', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        occurrenceOverrides: [
          OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 12, 18, 0), newDateTime: DateTime(2026, 1, 14, 20, 0)),
        ],
      );
      final resolved = generateResolvedOccurrencesInRange(client, rangeStart: DateTime(2026, 1, 1), rangeEnd: DateTime(2026, 1, 31));
      final moved = resolved.firstWhere((r) => r.scheduledFor == DateTime(2026, 1, 14, 20, 0));

      expect(moved.originalScheduledFor, DateTime(2026, 1, 12, 18, 0));
    });

    test('moved INTO the queried range from an original date outside it still appears', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        occurrenceOverrides: [
          // Original Monday is in January; moved into February.
          OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 26, 18, 0), newDateTime: DateTime(2026, 2, 4, 20, 0)),
        ],
      );

      final februaryOnly = generateResolvedOccurrencesInRange(client, rangeStart: DateTime(2026, 2, 1), rangeEnd: DateTime(2026, 2, 28));
      expect(februaryOnly.map((r) => r.scheduledFor), contains(DateTime(2026, 2, 4, 20, 0)));

      final januaryOnly = generateResolvedOccurrencesInRange(client, rangeStart: DateTime(2026, 1, 1), rangeEnd: DateTime(2026, 1, 31));
      expect(januaryOnly.map((r) => r.scheduledFor), isNot(contains(DateTime(2026, 1, 26, 18, 0))),
          reason: 'the original slot must not still show up now that it has been moved out');
    });
  });

  group('generateResolvedOccurrencesInRange — cancelled occurrence', () {
    test('is absent from generateResolvedOccurrencesInRange, generateOccurrencesInRange, upcomingThisWeek and registerableNow', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        occurrenceOverrides: [
          OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 19, 18, 0), newDateTime: null),
        ],
      );

      final resolved = generateResolvedOccurrencesInRange(client, rangeStart: DateTime(2026, 1, 1), rangeEnd: DateTime(2026, 1, 31));
      expect(resolved.map((r) => r.scheduledFor), isNot(contains(DateTime(2026, 1, 19, 18, 0))));

      final bare = generateOccurrencesInRange(client, rangeStart: DateTime(2026, 1, 1), rangeEnd: DateTime(2026, 1, 31));
      expect(bare, isNot(contains(DateTime(2026, 1, 19, 18, 0))));

      final upcoming = upcomingThisWeek([client], {}, DateTime(2026, 1, 19, 8, 0));
      expect(upcoming.any((o) => isSameDate(o.scheduledFor, DateTime(2026, 1, 19))), isFalse);

      final registerable = registerableNow([client], {}, DateTime(2026, 1, 19, 20, 0));
      expect(registerable.any((o) => isSameDate(o.scheduledFor, DateTime(2026, 1, 19))), isFalse);
    });
  });

  test('Quinzenal: an override on one occurrence does not perturb the biweekly parity of the others', () {
    final client = _weeklyClient(
      weekday: DateTime.wednesday,
      startDate: DateTime(2026, 1, 7),
      frequency: 'Quinzenal',
      occurrenceOverrides: [
        OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 21, 18, 0), newDateTime: DateTime(2026, 1, 22, 18, 0)),
      ],
    );

    final resolved = generateResolvedOccurrencesInRange(client, rangeStart: DateTime(2026, 1, 1), rangeEnd: DateTime(2026, 2, 28));
    final dates = resolved.map((r) => r.scheduledFor).toList();

    // Expected cadence (every 2 weeks): 01-07, 01-21(->01-22 moved), 02-04, 02-18.
    expect(dates, contains(DateTime(2026, 1, 7, 18, 0)));
    expect(dates, contains(DateTime(2026, 1, 22, 18, 0))); // moved
    expect(dates, isNot(contains(DateTime(2026, 1, 21, 18, 0))));
    expect(dates, contains(DateTime(2026, 2, 4, 18, 0)));
    expect(dates, contains(DateTime(2026, 2, 18, 18, 0)));
  });

  group('registering a moved occurrence', () {
    test('groups into the correct weekly/monthly payment cycle after being moved across months', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        occurrenceOverrides: [
          OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 26, 18, 0), newDateTime: DateTime(2026, 2, 2, 18, 0)),
        ],
      );
      final sessions = [
        _session(DateTime(2026, 1, 5, 18, 0)),
        _session(DateTime(2026, 1, 12, 18, 0)),
        _session(DateTime(2026, 1, 19, 18, 0)),
        _session(DateTime(2026, 2, 2, 18, 0)), // registered using the MOVED date
      ];

      final groups = computePaymentCycles(client, sessions);
      final january = groups.firstWhere((g) => g.periodStart == DateTime(2026, 1, 1));
      final february = groups.firstWhere((g) => g.periodStart == DateTime(2026, 2, 1));

      expect(january.totalSessions, 3, reason: 'the moved session must NOT be counted in January');
      expect(february.totalSessions, 1, reason: 'the moved session must be counted in February instead');
      expect(january.periodEnd, DateTime(2026, 1, 19, 23, 59, 59, 999),
          reason: "January's cycle must close on its own last real session (19th), not extend to the vacated 26th");
    });

    test('a moved occurrence does not reappear in upcomingThisWeek/registerableNow once registered', () {
      final movedTo = DateTime(2026, 1, 14, 20, 0);
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        occurrenceOverrides: [
          OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 12, 18, 0), newDateTime: movedTo),
        ],
      );
      final sessionsByClient = {
        'c1': [_session(movedTo)],
      };

      final now = DateTime(2026, 1, 14, 21, 0);
      final registerable = registerableNow([client], sessionsByClient, now);
      expect(registerable.any((o) => o.scheduledFor == movedTo), isFalse);
    });
  });

  group('upsertOverride / removeOverrideForDay', () {
    test('a second action on the same original day replaces the first instead of duplicating', () {
      final original = DateTime(2026, 1, 12, 18, 0);
      var overrides = <OccurrenceOverride>[];
      overrides = upsertOverride(overrides, OccurrenceOverride(originalScheduledFor: original, newDateTime: DateTime(2026, 1, 13, 18, 0)));
      overrides = upsertOverride(overrides, OccurrenceOverride(originalScheduledFor: original, newDateTime: DateTime(2026, 1, 14, 20, 0)));

      expect(overrides.length, 1);
      expect(overrides.single.newDateTime, DateTime(2026, 1, 14, 20, 0));
    });

    test('removeOverrideForDay reverts to the single original occurrence', () {
      final original = DateTime(2026, 1, 12, 18, 0);
      final overrides = [OccurrenceOverride(originalScheduledFor: original, newDateTime: DateTime(2026, 1, 14, 20, 0))];

      final reverted = removeOverrideForDay(overrides, original);
      expect(reverted, isEmpty);
    });

    test('removeOverrideForDay only removes the matching day, leaving others intact', () {
      final overrides = [
        OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 12, 18, 0), newDateTime: DateTime(2026, 1, 14, 20, 0)),
        OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 19, 18, 0), newDateTime: null),
      ];

      final result = removeOverrideForDay(overrides, DateTime(2026, 1, 12));
      expect(result.length, 1);
      expect(result.single.originalScheduledFor, DateTime(2026, 1, 19, 18, 0));
    });
  });
}
