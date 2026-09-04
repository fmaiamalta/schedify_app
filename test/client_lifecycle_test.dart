// Tests for clientHasUpcomingSchedule (schedule_logic.dart), used to derive
// the "Inativo" badge in Alunos and to exclude a client from Disciplina's
// enrolled count — without ever deleting the client's own record.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/services/schedule_logic.dart';

Client _weeklyClient({
  required int weekday,
  required DateTime startDate,
  DateTime? endDate,
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
    endDate: endDate,
    paymentType: PaymentType.mensal,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
    occurrenceOverrides: occurrenceOverrides,
  );
}

Client _avulsoClient({required DateTime date}) {
  return Client(
    id: 'c2',
    activityType: ActivityType.education,
    name: 'Aluno Avulso',
    contactEmail: '',
    contactPhone: '',
    notes: '',
    serviceType: 'Física',
    sessionFrequency: 'Avulso',
    slots: [WeeklySlot(weekday: date.weekday, time: TimeOfDay(hour: date.hour, minute: date.minute))],
    sessionDurationMinutes: 60,
    startDate: date,
    endDate: null,
    paymentType: PaymentType.avulso,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
  );
}

void main() {
  final now = DateTime(2026, 6, 15, 10, 0); // segunda-feira

  group('clientHasUpcomingSchedule — horário recorrente', () {
    test('sem data de fim: sempre ativo, mesmo anos depois de começar', () {
      final client = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2020, 1, 6));
      expect(clientHasUpcomingSchedule(client, now), isTrue);
    });

    test('data de fim no futuro: ainda ativo', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2026, 12, 31),
      );
      expect(clientHasUpcomingSchedule(client, now), isTrue);
    });

    test('data de fim já passada: inativo', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2025, 1, 6),
        endDate: DateTime(2026, 5, 1),
      );
      expect(clientHasUpcomingSchedule(client, now), isFalse);
    });

    test('data de fim é precisamente hoje: ainda conta como ativo (o dia de hoje ainda é válido)', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2026, 6, 15),
      );
      expect(clientHasUpcomingSchedule(client, now), isTrue);
    });
  });

  group('clientHasUpcomingSchedule — Avulso', () {
    test('data única no futuro: ativo', () {
      final client = _avulsoClient(date: DateTime(2026, 6, 20, 18, 0));
      expect(clientHasUpcomingSchedule(client, now), isTrue);
    });

    test('data única já passada: inativo', () {
      final client = _avulsoClient(date: DateTime(2026, 6, 10, 18, 0));
      expect(clientHasUpcomingSchedule(client, now), isFalse);
    });

    test('data única é hoje mas a hora já passou (ex.: registada e paga de manhã): inativo', () {
      // now = 2026-06-15 10:00; a sessão de hoje era às 08:00, já aconteceu.
      final client = _avulsoClient(date: DateTime(2026, 6, 15, 8, 0));
      expect(clientHasUpcomingSchedule(client, now), isFalse);
    });

    test('data única é hoje e a hora ainda não chegou: ativo', () {
      // now = 2026-06-15 10:00; a sessão de hoje é só às 18:00.
      final client = _avulsoClient(date: DateTime(2026, 6, 15, 18, 0));
      expect(clientHasUpcomingSchedule(client, now), isTrue);
    });
  });

  group('clientHasUpcomingSchedule — overrides pontuais', () {
    test('a única ocorrência restante foi cancelada: inativo, mesmo com data de fim no futuro', () {
      // Weekly com data de fim já passada logo a seguir à última ocorrência,
      // e essa última ocorrência foi cancelada — sem overrides não haveria
      // nenhuma ocorrência de qualquer forma, mas confirma-se explicitamente
      // que o cancelamento não "inventa" atividade.
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 15),
      );
      final cancelled = client.copyWith(
        occurrenceOverrides: [
          OccurrenceOverride(originalScheduledFor: DateTime(2026, 6, 15, 18, 0), newDateTime: null),
        ],
      );
      expect(clientHasUpcomingSchedule(cancelled, now), isFalse);
    });

    test('reagendada para uma data futura fora da série original: ativo', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 8),
        occurrenceOverrides: [
          OccurrenceOverride(originalScheduledFor: DateTime(2026, 6, 8, 18, 0), newDateTime: DateTime(2026, 6, 25, 18, 0)),
        ],
      );
      expect(clientHasUpcomingSchedule(client, now), isTrue);
    });
  });
}
