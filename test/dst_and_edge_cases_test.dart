import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/services/schedule_logic.dart';

Client _weeklyClient({
  required int weekday,
  required DateTime startDate,
  DateTime? endDate,
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
    endDate: endDate,
    paymentType: paymentType,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
  );
}

int _idCounter = 0;
SessionRecord _session(String clientId, DateTime scheduledFor) {
  _idCounter++;
  return SessionRecord(
    id: 's$_idCounter',
    clientId: clientId,
    registeredAt: scheduledFor,
    scheduledFor: scheduledFor,
    durationMinutes: 60,
    amount: 20,
    isPaid: false,
  );
}

void main() {
  group('DST (Europe/Lisbon spring-forward, 2026-03-29) — regression coverage after the fix', () {
    test(
      'sanity: raw DateTime.add(Duration(days:1)) does drift local time-of-day away from '
      'midnight across a DST boundary -- this is exactly why schedule_logic.dart uses '
      'addCalendarDays/calendarDaysBetween instead of Duration-based day arithmetic',
      () {
        var cursor = DateTime(2026, 3, 23); // Monday, midnight, well before the transition.
        for (var i = 0; i < 7; i++) {
          cursor = cursor.add(const Duration(days: 1));
        }
        // By 2026-03-30 the naive "+1 day" stepping drifts to 01:00 instead of staying at
        // midnight, purely because of the DST spring-forward on 03-29.
        expect(cursor, DateTime(2026, 3, 30, 1, 0));
        expect(cursor.hour, isNot(0));
      },
    );

    test(
      'generateOccurrencesInRange no longer drops a valid weekly occurrence that falls '
      'exactly on rangeEnd, even when the range spans a DST transition',
      () {
        // Weekly Thursday sessions, active well before March 2026.
        final client = _weeklyClient(weekday: DateTime.thursday, startDate: DateTime(2025, 1, 6));

        // Range: 2026-03-23 (Mon) .. 2026-04-02 (Thu). This spans the 2026-03-29
        // spring-forward. Expected Thursdays in range: 2026-03-26 and 2026-04-02.
        final occurrences = generateOccurrencesInRange(
          client,
          rangeStart: DateTime(2026, 3, 23),
          rangeEnd: DateTime(2026, 4, 2),
        );

        final dates = occurrences.map((d) => DateTime(d.year, d.month, d.day)).toList();

        expect(dates, [DateTime(2026, 3, 26), DateTime(2026, 4, 2)],
            reason: 'Fixed via addCalendarDays: both Thursdays must be present, including '
                'the one that falls exactly on rangeEnd after the DST transition.');
      },
    );

    test(
      'a monthly-payment client whose only weekly occurrence in a given month lands on '
      'the last calendar day now gets the correct payment cycle end date, even when DST '
      'occurred earlier in that same month',
      () {
        // Tuesday weekly sessions. 2026-03-31 is a Tuesday and the last day of March.
        final client = _weeklyClient(
          weekday: DateTime.tuesday,
          startDate: DateTime(2025, 1, 7),
          paymentType: PaymentType.mensal,
        );
        final sessions = [
          _session('c1', DateTime(2026, 3, 3, 18, 0)),
          _session('c1', DateTime(2026, 3, 31, 18, 0)),
        ];

        final groups = computePaymentCycles(client, sessions);
        final march = groups.firstWhere((g) => g.periodStart == DateTime(2026, 3, 1));

        expect(march.periodEnd, DateTime(2026, 3, 31, 23, 59, 59, 999),
            reason: 'Fixed: the cycle now closes on the real last occurrence, 2026-03-31, '
                'instead of silently falling back to an earlier date.');
      },
    );
  });

  group('_monthlyPeriodEnd when a client\'s schedule is edited after sessions were '
      'already registered (mensal payment type groups a whole calendar month '
      'together regardless of weekday, so this is intentional, not a bug)', () {
    test(
      'editing a client\'s weekly slot to a different weekday, WHERE the new weekday '
      'still has occurrences that month, reassigns periodEnd to the new schedule\'s '
      'last occurrence -- intentional: any new session matching the edited schedule '
      'would still join this same monthly group, so the cycle must stay open until '
      'the new schedule\'s last occurrence that month, not the orphaned session\'s day',
      () {
        // Client originally met on Mondays; a session was registered for Monday 2026-01-05.
        // The user then edits the client to Fridays (a very normal "the day changed" edit).
        final editedClient = _weeklyClient(weekday: DateTime.friday, startDate: DateTime(2026, 1, 2));
        final orphanedSession = _session('c1', DateTime(2026, 1, 5, 18, 0)); // a Monday, no longer a valid slot

        final group = computePaymentCycles(editedClient, [orphanedSession]).single;

        expect(group.periodEnd, DateTime(2026, 1, 30, 23, 59, 59, 999));
      },
    );

    test(
      'when the edited/new schedule has NO occurrences at all in the month of a '
      'historical session (e.g. the client\'s startDate was pushed forward past that '
      'month), the cycle now closes right after the last session that was actually '
      'registered, instead of waiting for the plain calendar end-of-month with '
      'nothing new ever coming',
      () {
        // Client's schedule now only starts 2026-02-01 (e.g. re-enrolled later),
        // but a session was already registered back in January under the old setup.
        final editedClient = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2026, 2, 1));
        final orphanedSession = _session('c1', DateTime(2026, 1, 5, 18, 0));

        final group = computePaymentCycles(editedClient, [orphanedSession]).single;

        expect(group.periodEnd, DateTime(2026, 1, 5, 23, 59, 59, 999),
            reason: 'Fixed: the current schedule has zero occurrences in January, so '
                'nothing more can ever join this cycle -- it must close right after the '
                'last actually-registered session (01-05), not wait for 01-31.');
        expect(group.isClosed(DateTime(2026, 1, 6)), isTrue);
        expect(group.isClosed(DateTime(2026, 1, 5, 23, 59, 59)), isFalse);
      },
    );
  });

  group('Quinzenal (biweekly) parity is preserved across a DST transition (regression)', () {
    test(
      'weeksBetween keeps the correct 14-day cadence across the 2026-03-29 spring-forward, '
      'via calendarDaysBetween instead of a Duration-based day count',
      () {
        // Biweekly Wednesday sessions starting 2026-01-07 (a Wednesday).
        // Expected cadence (every 2 weeks): 01-07, 01-21, 02-04, 02-18, 03-04, 03-18,
        // 04-01, 04-15 ...
        final client = _weeklyClient(
          weekday: DateTime.wednesday,
          startDate: DateTime(2026, 1, 7),
          frequency: 'Quinzenal',
        );

        final occurrences = generateOccurrencesInRange(
          client,
          rangeStart: DateTime(2026, 1, 1),
          rangeEnd: DateTime(2026, 4, 30),
        );
        final dates = occurrences.map((d) => DateTime(d.year, d.month, d.day)).toList();

        final expected = [
          DateTime(2026, 1, 7),
          DateTime(2026, 1, 21),
          DateTime(2026, 2, 4),
          DateTime(2026, 2, 18),
          DateTime(2026, 3, 4),
          DateTime(2026, 3, 18),
          DateTime(2026, 4, 1),
          DateTime(2026, 4, 15),
          DateTime(2026, 4, 29),
        ];

        expect(dates, expected,
            reason: 'If this fails, the DST transition on 2026-03-29 perturbed the '
                'biweekly parity computed by weeksBetween (which truncates a Duration '
                'to whole days via .inDays, vulnerable to the same 1-hour DST drift).');
      },
    );
  });

  group('Avulso payment-cycle grouping: same-day sessions (regression)', () {
    test(
      'computePaymentCycles produces SEPARATE groups (one per session) for two Avulso '
      'sessions registered on the same calendar day for the same client -- both groups '
      'share an identical periodStart (the shared date), but PaymentCycleGroup.cycleId '
      'must still be distinct per group (keyed by the session id for Avulso), so the UI '
      '"report sent" tracking does not collide between them.',
      () {
        final client = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2026, 1, 5))
            .copyWith(sessionFrequency: 'Avulso', paymentType: PaymentType.avulso);
        final sessions = [
          _session('c1', DateTime(2026, 2, 10, 9, 0)),
          _session('c1', DateTime(2026, 2, 10, 15, 0)), // same day, different time
        ];

        final groups = computePaymentCycles(client, sessions);

        expect(groups.length, 2, reason: 'two distinct sessions -> two distinct payment groups');
        expect(groups[0].periodStart, groups[1].periodStart,
            reason: 'both groups do share the same periodStart (dateOnly of the shared day)');
        expect(groups[0].cycleId, isNot(groups[1].cycleId),
            reason: 'Fixed: cycleId must NOT collide even though periodStart does, so the '
                '"report sent" tracking key built from it (client.id + cycleId) stays unique '
                'per Avulso session.');
      },
    );
  });
}
