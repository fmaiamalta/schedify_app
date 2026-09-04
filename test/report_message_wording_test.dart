// Regression coverage for the fix to AppStrings.reportMessage()/buildReportMessage().
//
// The fix to registeredSnackbar()/noneRecordedYet() (gender agreement) didn't
// touch AppStrings.reportMessage() (the actual WhatsApp/email text sent to a
// real client to request payment), which used to hardcode education-specific
// wording ("aulas/formação", "aulas/sessões") regardless of the client's
// activityType. Fixed by threading sessionPluralLower (derived from
// client.activityType) through buildReportMessage -> reportMessage.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/i18n/app_strings.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/services/report_service.dart';
import 'package:schedify_app/services/schedule_logic.dart';

Client _client(ActivityType type, {String serviceType = ''}) {
  return Client(
    id: 'c1',
    activityType: type,
    name: 'Cliente Teste',
    contactEmail: '',
    contactPhone: '912345678',
    notes: '',
    serviceType: serviceType,
    sessionFrequency: 'Semanal',
    slots: const [WeeklySlot(weekday: 1, time: TimeOfDay(hour: 18, minute: 0))],
    sessionDurationMinutes: 60,
    startDate: DateTime(2026, 1, 5),
    endDate: null,
    paymentType: PaymentType.mensal,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
  );
}

PaymentCycleGroup _cycle(Client client) {
  return PaymentCycleGroup(
    client: client,
    frequency: PaymentType.mensal,
    periodStart: DateTime(2026, 1, 1),
    periodEnd: DateTime(2026, 1, 31, 23, 59, 59, 999),
    sessions: [
      SessionRecord(
        id: 's1',
        clientId: client.id,
        registeredAt: DateTime(2026, 1, 5),
        scheduledFor: DateTime(2026, 1, 5, 18, 0),
        durationMinutes: 60,
        amount: 20,
      ),
    ],
  );
}

void main() {
  group('buildReportMessage (pt-PT) — wording now adapts to activityType', () {
    final strings = AppStrings(AppLanguage.pt);

    test('Fitness client report says "treinos", never "aulas"', () {
      final client = _client(ActivityType.fitness, serviceType: 'Musculação');
      final message = buildReportMessage(client: client, cycle: _cycle(client), strings: strings);

      expect(message, contains('treinos'));
      expect(message, isNot(contains('aulas')));
    });

    test('Fitness client report says "dos treinos" (masculine article), not "das treinos"', () {
      final client = _client(ActivityType.fitness, serviceType: 'Musculação');
      final message = buildReportMessage(client: client, cycle: _cycle(client), strings: strings);

      expect(message, contains('dos treinos'));
      expect(message, isNot(contains('das treinos')));
    });

    test('Education client report keeps "das aulas" (feminine article)', () {
      final client = _client(ActivityType.education, serviceType: 'Matemática');
      final message = buildReportMessage(client: client, cycle: _cycle(client), strings: strings);

      expect(message, contains('das aulas'));
    });

    test('report money total uses the same decimal format as the rest of the app (period, not comma)', () {
      final client = _client(ActivityType.education, serviceType: 'Matemática');
      final message = buildReportMessage(client: client, cycle: _cycle(client), strings: strings);

      expect(message, contains('20.00€'));
      expect(message, isNot(contains('20,00€')));
    });

    test('Health client report says "consultas", never "aulas"', () {
      final client = _client(ActivityType.health, serviceType: 'Fisioterapia');
      final message = buildReportMessage(client: client, cycle: _cycle(client), strings: strings);

      expect(message, contains('consultas'));
      expect(message, isNot(contains('aulas')));
    });

    test('Education client report still says "aulas" (unchanged for its own activity type)', () {
      final client = _client(ActivityType.education, serviceType: 'Matemática');
      final message = buildReportMessage(client: client, cycle: _cycle(client), strings: strings);

      expect(message, contains('aulas'));
    });
  });

  test('English report message names the activity\'s own session word (e.g. "workouts"), not a generic one', () {
    final englishStrings = AppStrings(AppLanguage.en);
    final client = _client(ActivityType.fitness, serviceType: 'Weight training');
    final message = buildReportMessage(client: client, cycle: _cycle(client), strings: englishStrings);

    expect(message, contains('workouts'));
    expect(message, isNot(contains('class')));
  });
}
