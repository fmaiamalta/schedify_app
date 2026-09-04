import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/services/schedule_logic.dart';

Client _weeklyClient({required int weekday, required DateTime startDate}) {
  return Client(
    id: 'c1',
    activityType: ActivityType.education,
    name: 'Aluno Teste',
    contactEmail: '',
    contactPhone: '',
    notes: '',
    serviceType: 'Matemática',
    sessionFrequency: 'Semanal',
    slots: [WeeklySlot(weekday: weekday, time: const TimeOfDay(hour: 18, minute: 0))],
    sessionDurationMinutes: 60,
    startDate: startDate,
    endDate: null,
    paymentType: PaymentType.mensal,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
  );
}

Client _monthlyClient({required DateTime startDate}) {
  return Client(
    id: 'c1',
    activityType: ActivityType.education,
    name: 'Aluno Teste',
    contactEmail: '',
    contactPhone: '',
    notes: '',
    serviceType: 'Matemática',
    sessionFrequency: 'Mensal',
    slots: const [WeeklySlot(weekday: 1, time: TimeOfDay(hour: 18, minute: 0))],
    sessionDurationMinutes: 60,
    startDate: startDate,
    endDate: null,
    paymentType: PaymentType.mensal,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
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
    isPaid: false,
  );
}

void main() {
  group('computePaymentCycles (mensal) — fecha no dia da última aula do mês', () {
    // Segunda-feira, aulas semanais: 5, 12, 19 e 26 de janeiro de 2026.
    // 26/jan é a última segunda-feira do mês (o mês só termina a 31).
    test('periodEnd é o dia da última aula semanal do mês, não o último dia do calendário', () {
      final client = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2026, 1, 5));
      final sessions = [
        _session(DateTime(2026, 1, 5, 18, 0)),
        _session(DateTime(2026, 1, 12, 18, 0)),
      ];

      final group = computePaymentCycles(client, sessions).first;

      expect(group.periodEnd, DateTime(2026, 1, 26, 23, 59, 59, 999));
    });

    test('ciclo fecha logo a seguir à última aula do mês, sem esperar pelo fim do calendário', () {
      final client = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2026, 1, 5));
      final sessions = [_session(DateTime(2026, 1, 5, 18, 0))];
      final group = computePaymentCycles(client, sessions).first;

      // 27, 28, 29, 30 e 31 de janeiro já não têm mais aulas nesse mês.
      expect(group.isClosed(DateTime(2026, 1, 26, 23, 59, 59)), isFalse);
      expect(group.isClosed(DateTime(2026, 1, 27, 0, 0, 1)), isTrue);
      expect(group.isClosed(DateTime(2026, 1, 31, 23, 59, 59)), isTrue);
    });

    test('mês seguinte começa um ciclo novo mesmo tendo menos/mais aulas', () {
      final client = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2026, 1, 5));
      final sessions = [
        _session(DateTime(2026, 1, 26, 18, 0)),
        _session(DateTime(2026, 2, 2, 18, 0)),
      ];

      final groups = computePaymentCycles(client, sessions);

      expect(groups.length, 2);
    });

    test('respeita fevereiro bissexto: última quinta-feira é 24, não 29', () {
      final client = _weeklyClient(weekday: DateTime.thursday, startDate: DateTime(2028, 2, 3));
      final sessions = [_session(DateTime(2028, 2, 3, 18, 0))];
      final group = computePaymentCycles(client, sessions).first;

      expect(group.periodEnd, DateTime(2028, 2, 24, 23, 59, 59, 999));
      expect(group.isClosed(DateTime(2028, 2, 24, 23, 59, 59)), isFalse);
      expect(group.isClosed(DateTime(2028, 2, 25, 0, 0, 1)), isTrue);
    });

    test('cliente com aula mensal única: o ciclo termina no próprio dia dessa aula', () {
      final client = _monthlyClient(startDate: DateTime(2026, 1, 5));
      final sessions = [_session(DateTime(2026, 1, 5, 18, 0))];
      final group = computePaymentCycles(client, sessions).first;

      expect(group.periodEnd, DateTime(2026, 1, 5, 23, 59, 59, 999));
      expect(group.isClosed(DateTime(2026, 1, 6, 0, 0, 1)), isTrue);
    });
  });
}
