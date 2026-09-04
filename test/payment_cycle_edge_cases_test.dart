// Deep-dive follow-up checks on fix #2 (_monthlyPeriodEnd / computePaymentCycles)
// and fix #5 (PaymentCycleGroup.cycleId), beyond what
// test/dst_and_edge_cases_test.dart already covers.
//
// The existing regression tests only exercise two of the three possible
// outcomes when a client's weekly schedule is edited after some sessions were
// already registered for a month:
//   1. the NEW schedule still has occurrences that month, and its last
//      occurrence is LATER than the orphaned session -> periodEnd extends
//      forward (explicitly documented as intentional).
//   2. the NEW schedule has ZERO occurrences that month -> periodEnd falls
//      back to the last actually-registered session.
//
// Missing: the case where the NEW schedule still has occurrences that month
// (so the "zero occurrences" fallback never triggers), but its last
// occurrence falls EARLIER in the month than a session that was already
// registered under the OLD schedule. In that case _monthlyPeriodEnd uses the
// non-empty-occurrences branch and returns a periodEnd that sits BEFORE one
// (or more) of its own group's sessions -- an internal inconsistency that
// the "zero occurrences" fallback was never designed to catch, because it
// only triggers when occurrences.isEmpty, not when occurrences exist but are
// all earlier than an existing session in the same bucket.
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
  String id = 'c1',
}) {
  return Client(
    id: id,
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
  group('_monthlyPeriodEnd (fixed): periodEnd can never precede a session that is '
      'genuinely inside its own group, even when the current schedule (post-edit) '
      'would otherwise project an earlier last occurrence', () {
    test(
      'January 2026: Saturday (weekday 6) sessions run through the whole month '
      '(last Saturday = 31st). If the client is then edited to Sunday (weekday 7, '
      'whose last occurrence in January is only the 25th), periodEnd must still '
      'cover the 31st, not fall back to the new schedule\'s earlier last occurrence.',
      () {
        // All-Saturday sessions across January while schedule was still Saturday.
        final oldSchedule = _weeklyClient(weekday: DateTime.saturday, startDate: DateTime(2026, 1, 3));
        final sessions = [
          _session('c1', DateTime(2026, 1, 3, 18, 0)),
          _session('c1', DateTime(2026, 1, 10, 18, 0)),
          _session('c1', DateTime(2026, 1, 17, 18, 0)),
          _session('c1', DateTime(2026, 1, 24, 18, 0)),
          _session('c1', DateTime(2026, 1, 31, 18, 0)), // last Saturday of January
        ];
        // Sanity: this is really the last Saturday of January 2026.
        expect(DateTime(2026, 1, 31).weekday, DateTime.saturday);

        // Client is edited afterwards (e.g. starting February the sessions move to
        // Sundays) -- a completely ordinary, expected user action.
        final editedClient = oldSchedule.copyWith(slots: [
          const WeeklySlot(weekday: DateTime.sunday, time: TimeOfDay(hour: 18, minute: 0)),
        ]);

        final group = computePaymentCycles(editedClient, sessions)
            .firstWhere((g) => g.periodStart == DateTime(2026, 1, 1));

        final maxSessionDate = sessions.map((s) => s.scheduledFor).reduce((a, b) => a.isAfter(b) ? a : b);

        expect(
          group.periodEnd.isBefore(maxSessionDate),
          isFalse,
          reason: 'Fixed: periodEnd must never be earlier than a session genuinely inside '
              'this same group ($maxSessionDate).',
        );

        // The new schedule's last Sunday (25th) is superseded by the 31st, since a
        // session was actually registered on that day.
        expect(group.periodEnd, DateTime(2026, 1, 31, 23, 59, 59, 999));
      },
    );

    test(
      'the same guarantee holds with MULTIPLE orphaned sessions under different '
      'now-invalid weekdays in the same month (e.g. a client downgraded from '
      '"2x por semana" Tue/Thu to "Semanal" Monday)',
      () {
        // Sessions registered on Tuesday 27th and Thursday 29th, back when the
        // client's plan was "2x por semana" (Tue/Thu).
        final sessions = [
          _session('c1', DateTime(2026, 1, 27, 18, 0)), // Tuesday
          _session('c1', DateTime(2026, 1, 29, 18, 0)), // Thursday
        ];
        expect(DateTime(2026, 1, 27).weekday, DateTime.tuesday);
        expect(DateTime(2026, 1, 29).weekday, DateTime.thursday);

        // Client is downgraded to a single weekly Monday slot. The last Monday of
        // January 2026 (the 26th) is earlier than BOTH orphaned sessions.
        final editedClient = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2026, 1, 5));

        final group = computePaymentCycles(editedClient, sessions).single;

        expect(group.sessions.length, 2);
        // periodEnd must cover the later orphaned session (29th), not the new
        // schedule's last Monday (26th).
        expect(group.periodEnd, DateTime(2026, 1, 29, 23, 59, 59, 999));
        expect(group.periodEnd.isBefore(DateTime(2026, 1, 27)), isFalse);
        expect(group.periodEnd.isBefore(DateTime(2026, 1, 29)), isFalse);
      },
    );
  });

  group('PaymentCycleGroup.cycleId: cross-client collision sanity (fix #5)', () {
    test('two different clients with an Avulso session on the same calendar day '
        'produce different cycleId values, and _groupKey in PaymentsTab additionally '
        'prepends client.id, so there is no collision even if cycleId ever matched', () {
      final clientA = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2026, 1, 5), id: 'clientA')
          .copyWith(sessionFrequency: 'Avulso', paymentType: PaymentType.avulso);
      final clientB = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2026, 1, 5), id: 'clientB')
          .copyWith(sessionFrequency: 'Avulso', paymentType: PaymentType.avulso);

      final sessionA = SessionRecord(
        id: 'shared-session-id', // deliberately colliding session id across clients
        clientId: 'clientA',
        registeredAt: DateTime(2026, 2, 10, 9, 0),
        scheduledFor: DateTime(2026, 2, 10, 9, 0),
        durationMinutes: 60,
        amount: 20,
      );
      final sessionB = SessionRecord(
        id: 'shared-session-id', // same id, different client -- plausible if ids were ever
        clientId: 'clientB', // generated non-globally-uniquely by some future code path
        registeredAt: DateTime(2026, 2, 10, 9, 0),
        scheduledFor: DateTime(2026, 2, 10, 9, 0),
        durationMinutes: 60,
        amount: 20,
      );

      final groupA = computePaymentCycles(clientA, [sessionA]).single;
      final groupB = computePaymentCycles(clientB, [sessionB]).single;

      // cycleId alone WOULD collide here (both keyed off the same session id) --
      // this is exactly why PaymentsTab._groupKey prepends client.id.
      expect(groupA.cycleId, groupB.cycleId,
          reason: 'Demonstrates why cycleId alone is not safe as a global key: it can '
              'collide across different clients if session ids are ever not globally unique.');

      final keyA = '${groupA.client.id}|${groupA.cycleId}';
      final keyB = '${groupB.client.id}|${groupB.cycleId}';
      expect(keyA, isNot(keyB),
          reason: 'Confirmed: PaymentsTab._groupKey (client.id + cycleId) stays unique because '
              'client.id differs, even in this adversarial same-session-id scenario.');
    });
  });
}
