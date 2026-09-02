import 'package:flutter/material.dart';
import '../models.dart';

const int _maxGeneratedOccurrences = 1000;
const int _maxHorizonDays = 365 * 2;

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

DateTime startOfWeek(DateTime date) {
  final normalized = dateOnly(date);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

DateTime endOfWeek(DateTime date) {
  final start = startOfWeek(date);
  return DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
}

DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

DateTime endOfMonth(DateTime date) {
  final firstOfNext = DateTime(date.year, date.month + 1, 1);
  return firstOfNext.subtract(const Duration(days: 1));
}

int weeksBetween(DateTime from, DateTime to) {
  final fromWeek = startOfWeek(from);
  final toWeek = startOfWeek(to);
  return toWeek.difference(fromWeek).inDays ~/ 7;
}

/// Devolve os dias da semana exigidos pela frequência da sessão selecionada
/// (1 = Segunda ... 7 = Domingo, convenção [DateTime.weekday]).
int requiredWeekdayCount(String sessionFrequency) {
  switch (sessionFrequency) {
    case 'Semanal':
      return 1;
    case '2x por semana':
      return 2;
    case '3x por semana':
      return 3;
    case 'Quinzenal':
      return 1;
    case 'Mensal':
      return 1;
    default: // 'Avulso'
      return 0;
  }
}

/// Devolve a primeira data (>= [from]) cujo dia da semana esteja entre
/// [weekdays]. Se [from] já corresponder, devolve [from] sem alterar.
/// Usado para manter a Data de Início/Fim sempre coerente com os dias da
/// semana escolhidos no formulário.
DateTime nearestMatchingDate(DateTime from, List<int> weekdays) {
  if (weekdays.isEmpty) return from;
  var cursor = dateOnly(from);
  for (var i = 0; i < 7; i++) {
    if (weekdays.contains(cursor.weekday)) return cursor;
    cursor = cursor.add(const Duration(days: 1));
  }
  return from;
}

/// Resultado de uma data que não coincide com os dias da semana escolhidos.
class WeekdayMismatch {
  final int actualWeekday;
  final List<int> allowedWeekdays;
  const WeekdayMismatch({required this.actualWeekday, required this.allowedWeekdays});
}

/// Valida que a data cai num dos dias da semana escolhidos. `null` = válido.
WeekdayMismatch? validateDateMatchesWeekdays(DateTime date, List<WeeklySlot> slots) {
  if (slots.isEmpty) return null;
  final weekdays = slots.map((s) => s.weekday).toSet();
  if (!weekdays.contains(date.weekday)) {
    return WeekdayMismatch(actualWeekday: date.weekday, allowedWeekdays: weekdays.toList()..sort());
  }
  return null;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

/// Gera todas as ocorrências (data+hora) de um cliente entre `rangeStart` e
/// `rangeEnd` (inclusive), de acordo com a frequência de sessão escolhida.
List<DateTime> generateOccurrencesInRange(
  Client client, {
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  final seriesStart = dateOnly(client.startDate);
  final seriesEnd = client.endDate != null ? dateOnly(client.endDate!) : null;

  final effectiveRangeStart = dateOnly(rangeStart);
  final effectiveRangeEnd = dateOnly(rangeEnd);

  if (client.sessionFrequency == 'Avulso' || client.slots.isEmpty) {
    if (client.slots.isEmpty) return [];
    final occurrence = combineDateAndTime(seriesStart, client.slots.first.time);
    if (!seriesStart.isBefore(effectiveRangeStart) && !seriesStart.isAfter(effectiveRangeEnd)) {
      return [occurrence];
    }
    return [];
  }

  final loopEnd = seriesEnd != null && seriesEnd.isBefore(effectiveRangeEnd) ? seriesEnd : effectiveRangeEnd;
  if (loopEnd.isBefore(seriesStart)) return [];

  final loopStart = seriesStart.isAfter(effectiveRangeStart) ? seriesStart : effectiveRangeStart;

  final occurrences = <DateTime>[];

  if (client.sessionFrequency == 'Mensal') {
    final slot = client.slots.first;
    var cursor = DateTime(loopStart.year, loopStart.month, 1);
    var guard = 0;
    while (!cursor.isAfter(loopEnd) && occurrences.length < _maxGeneratedOccurrences && guard < 240) {
      final day = seriesStart.day.clamp(1, DateTime(cursor.year, cursor.month + 1, 0).day);
      final candidate = DateTime(cursor.year, cursor.month, day);
      final occurrence = combineDateAndTime(candidate, slot.time);
      if (!candidate.isBefore(seriesStart) &&
          (seriesEnd == null || !candidate.isAfter(seriesEnd)) &&
          !candidate.isBefore(loopStart) &&
          !candidate.isAfter(loopEnd)) {
        occurrences.add(occurrence);
      }
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
      guard++;
    }
    return occurrences;
  }

  if (client.sessionFrequency == 'Quinzenal') {
    final slot = client.slots.first;
    var cursor = loopStart;
    var guard = 0;
    while (!cursor.isAfter(loopEnd) && occurrences.length < _maxGeneratedOccurrences && guard < _maxHorizonDays) {
      if (cursor.weekday == slot.weekday) {
        final weeksDiff = weeksBetween(seriesStart, cursor);
        if (weeksDiff >= 0 && weeksDiff % 2 == 0) {
          occurrences.add(combineDateAndTime(cursor, slot.time));
        }
      }
      cursor = cursor.add(const Duration(days: 1));
      guard++;
    }
    return occurrences;
  }

  // Semanal / 2x por semana / 3x por semana: uma ocorrência por slot escolhido, todas as semanas.
  final timeByWeekday = {for (final slot in client.slots) slot.weekday: slot.time};
  var cursor = loopStart;
  var guard = 0;
  while (!cursor.isAfter(loopEnd) && occurrences.length < _maxGeneratedOccurrences && guard < _maxHorizonDays) {
    final time = timeByWeekday[cursor.weekday];
    if (time != null) {
      occurrences.add(combineDateAndTime(cursor, time));
    }
    cursor = cursor.add(const Duration(days: 1));
    guard++;
  }
  return occurrences;
}

/// Ocorrências planeadas desta semana (hoje a domingo) que ainda não foram registadas.
List<PlannedOccurrence> upcomingThisWeek(
  List<Client> clients,
  Map<String, List<SessionRecord>> sessionsByClient,
  DateTime now,
) {
  final weekEnd = endOfWeek(now);
  final result = <PlannedOccurrence>[];
  for (final client in clients) {
    final occurrences = generateOccurrencesInRange(client, rangeStart: now, rangeEnd: weekEnd);
    final registered = sessionsByClient[client.id] ?? [];
    for (final occurrence in occurrences) {
      final alreadyRegistered = registered.any((s) => isSameDate(s.scheduledFor, occurrence) && s.scheduledFor.hour == occurrence.hour && s.scheduledFor.minute == occurrence.minute);
      if (!alreadyRegistered) {
        result.add(PlannedOccurrence(client: client, scheduledFor: occurrence));
      }
    }
  }
  result.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  return result;
}

/// Ocorrências de hoje ou até 1 semana atrás, ainda por registar.
List<PlannedOccurrence> registerableNow(
  List<Client> clients,
  Map<String, List<SessionRecord>> sessionsByClient,
  DateTime now,
) {
  final rangeStart = dateOnly(now).subtract(const Duration(days: 7));
  final rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final result = <PlannedOccurrence>[];
  for (final client in clients) {
    final occurrences = generateOccurrencesInRange(client, rangeStart: rangeStart, rangeEnd: rangeEnd);
    final registered = sessionsByClient[client.id] ?? [];
    for (final occurrence in occurrences) {
      final alreadyRegistered = registered.any((s) => isSameDate(s.scheduledFor, occurrence) && s.scheduledFor.hour == occurrence.hour && s.scheduledFor.minute == occurrence.minute);
      if (!alreadyRegistered) {
        result.add(PlannedOccurrence(client: client, scheduledFor: occurrence));
      }
    }
  }
  result.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  return result;
}

double calculateSessionAmount(Client client, int durationMinutes) {
  double amount;
  if (client.rateType == RateType.total) {
    amount = client.hourlyRate;
  } else {
    amount = (client.hourlyRate / 60) * durationMinutes;
  }
  if (client.hasVat) {
    amount = amount * 1.23;
  }
  return double.parse(amount.toStringAsFixed(2));
}

class ActivityStats {
  final ActivityType activityType;
  final int registeredCount;
  final double receivedAmount;

  const ActivityStats({required this.activityType, required this.registeredCount, required this.receivedAmount});
}

/// Registos e pagamentos efetuados, agregados por Tipo de Atividade — usado
/// no Dashboard para dar uma visão global mesmo quando há mais do que uma
/// área de trabalho em uso (ex.: ensino + fitness + outros serviços).
List<ActivityStats> statsByActivity(List<Client> clients, Map<String, List<SessionRecord>> sessionsByClient) {
  final counts = <ActivityType, int>{};
  final amounts = <ActivityType, double>{};

  for (final client in clients) {
    final sessions = sessionsByClient[client.id] ?? [];
    if (sessions.isEmpty) continue;
    counts[client.activityType] = (counts[client.activityType] ?? 0) + sessions.length;
    final paid = sessions.where((s) => s.isPaid).fold(0.0, (sum, s) => sum + s.amount);
    amounts[client.activityType] = (amounts[client.activityType] ?? 0) + paid;
  }

  final result = [
    for (final type in ActivityType.values)
      if ((counts[type] ?? 0) > 0)
        ActivityStats(
          activityType: type,
          registeredCount: counts[type] ?? 0,
          receivedAmount: double.parse((amounts[type] ?? 0).toStringAsFixed(2)),
        ),
  ];
  return result;
}

/// Um grupo de sessões que pertence ao mesmo ciclo de pagamento (semana, mês, ou
/// sessão avulsa), usado no ecrã de Pagamentos para acumulação e relatório.
class PaymentCycleGroup {
  final Client client;
  final PaymentType frequency;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<SessionRecord> sessions;

  PaymentCycleGroup({
    required this.client,
    required this.frequency,
    required this.periodStart,
    required this.periodEnd,
    required this.sessions,
  });

  int get totalSessions => sessions.length;

  double get totalAmount {
    final total = sessions.fold<double>(0, (sum, s) => sum + s.amount);
    return double.parse(total.toStringAsFixed(2));
  }

  bool get isFullyPaid => sessions.isNotEmpty && sessions.every((s) => s.isPaid);

  bool get hasPending => sessions.any((s) => !s.isPaid);

  /// Fechado = já passou o fim do período (pronto para relatório/pagamento).
  bool isClosed(DateTime now) => now.isAfter(periodEnd);

  String periodLabel([AppLanguage language = AppLanguage.pt]) {
    switch (frequency) {
      case PaymentType.avulso:
        return _formatDate(periodStart);
      case PaymentType.semanal:
        return '${_formatDate(periodStart)} - ${_formatDate(periodEnd)}';
      case PaymentType.mensal:
        const monthsPt = [
          'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
          'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
        ];
        const monthsEn = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ];
        final months = language == AppLanguage.en ? monthsEn : monthsPt;
        return '${months[periodStart.month - 1]} ${periodStart.year}';
    }
  }
}

/// Agrupa as sessões registadas de um cliente em ciclos de pagamento, de acordo
/// com a frequência de pagamento escolhida (Avulso = 1 sessão por ciclo,
/// Semanal = semana ISO, Mensal = mês civil).
List<PaymentCycleGroup> computePaymentCycles(Client client, List<SessionRecord> sessions) {
  if (sessions.isEmpty) return [];

  if (client.paymentType == PaymentType.avulso) {
    return sessions
        .map((s) => PaymentCycleGroup(
              client: client,
              frequency: PaymentType.avulso,
              periodStart: dateOnly(s.scheduledFor),
              periodEnd: dateOnly(s.scheduledFor),
              sessions: [s],
            ))
        .toList();
  }

  final groups = <String, PaymentCycleGroup>{};
  for (final session in sessions) {
    final DateTime periodStart;
    final DateTime periodEnd;
    if (client.paymentType == PaymentType.semanal) {
      periodStart = startOfWeek(session.scheduledFor);
      periodEnd = dateOnly(endOfWeek(session.scheduledFor));
    } else {
      periodStart = startOfMonth(session.scheduledFor);
      periodEnd = endOfMonth(session.scheduledFor);
    }
    final key = '${periodStart.toIso8601String()}_${periodEnd.toIso8601String()}';
    final existing = groups[key];
    if (existing == null) {
      groups[key] = PaymentCycleGroup(
        client: client,
        frequency: client.paymentType,
        periodStart: periodStart,
        periodEnd: periodEnd,
        sessions: [session],
      );
    } else {
      existing.sessions.add(session);
    }
  }

  final result = groups.values.toList();
  result.sort((a, b) => b.periodStart.compareTo(a.periodStart));
  return result;
}
