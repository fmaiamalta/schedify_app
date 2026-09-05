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

int _idCounter = 0;
SessionRecord _sessionFor(String clientId, DateTime scheduledFor) {
  _idCounter++;
  return SessionRecord(
    id: 's$_idCounter',
    clientId: clientId,
    registeredAt: scheduledFor,
    scheduledFor: scheduledFor,
    durationMinutes: 60,
    amount: 20,
  );
}

void main() {
  final now = DateTime(2026, 6, 15, 10, 0); // segunda-feira

  group('clientHasUpcomingSchedule — horário recorrente', () {
    test('sem data de fim: sempre ativo, mesmo anos depois de começar', () {
      final client = _weeklyClient(weekday: DateTime.monday, startDate: DateTime(2020, 1, 6));
      expect(clientHasUpcomingSchedule(client, const [], now), isTrue);
    });

    test('data de fim no futuro: ainda ativo', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2026, 12, 31),
      );
      expect(clientHasUpcomingSchedule(client, const [], now), isTrue);
    });

    test('data de fim já passada há mais de 1 semana, sem nada por registar: inativo', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2025, 1, 6),
        endDate: DateTime(2026, 5, 1),
      );
      expect(clientHasUpcomingSchedule(client, const [], now), isFalse);
    });

    test('data de fim é precisamente hoje: ainda conta como ativo (o dia de hoje ainda é válido)', () {
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 1, 5),
        endDate: DateTime(2026, 6, 15),
      );
      expect(clientHasUpcomingSchedule(client, const [], now), isTrue);
    });
  });

  group('clientHasUpcomingSchedule — Avulso', () {
    test('data única no futuro, ainda não registada: ativo', () {
      final client = _avulsoClient(date: DateTime(2026, 6, 20, 18, 0));
      expect(clientHasUpcomingSchedule(client, const [], now), isTrue);
    });

    test('data única há mais de 1 semana, nunca registada: inativo (fora da janela do Registar)', () {
      final client = _avulsoClient(date: DateTime(2026, 6, 1, 18, 0));
      expect(clientHasUpcomingSchedule(client, const [], now), isFalse);
    });

    test('criado hoje, ainda não registado (mesmo com a hora agendada já passada): continua ativo', () {
      // Reportado em produção: um Avulso novo, criado para hoje, ficava
      // "Inativo" imediatamente ao ser criado — mas continuava a aparecer
      // em Registar e a poder ser marcado como pago, o que era contraditório.
      // A sessão de hoje era às 08:00 (já passou face a now=10:00), mas
      // ainda não foi registada — tem de continuar ativo.
      final client = _avulsoClient(date: DateTime(2026, 6, 15, 8, 0));
      expect(clientHasUpcomingSchedule(client, const [], now), isTrue);
    });

    test('data única de hoje, já registada e paga: inativo (nada mais por fazer)', () {
      final scheduledFor = DateTime(2026, 6, 15, 8, 0);
      final client = _avulsoClient(date: scheduledFor);
      final sessions = [_sessionFor(client.id, scheduledFor)];
      expect(clientHasUpcomingSchedule(client, sessions, now), isFalse);
    });

    test('data única de há 3 dias, ainda não registada (dentro da janela do Registar): ativo', () {
      final client = _avulsoClient(date: DateTime(2026, 6, 12, 18, 0));
      expect(clientHasUpcomingSchedule(client, const [], now), isTrue);
    });
  });

  group('clientHasUpcomingSchedule — overrides pontuais', () {
    test('a única ocorrência da série foi cancelada: inativo', () {
      // startDate == endDate: a série gera uma única ocorrência (hoje), que
      // é depois cancelada — sem overrides não haveria nenhuma ocorrência de
      // qualquer forma, mas confirma-se explicitamente que o cancelamento
      // não "inventa" atividade.
      final client = _weeklyClient(
        weekday: DateTime.monday,
        startDate: DateTime(2026, 6, 15),
        endDate: DateTime(2026, 6, 15),
      );
      final cancelled = client.copyWith(
        occurrenceOverrides: [
          OccurrenceOverride(originalScheduledFor: DateTime(2026, 6, 15, 18, 0), newDateTime: null),
        ],
      );
      expect(clientHasUpcomingSchedule(cancelled, const [], now), isFalse);
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
      expect(clientHasUpcomingSchedule(client, const [], now), isTrue);
    });
  });
}
