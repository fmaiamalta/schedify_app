import 'package:flutter/material.dart';
import '../models.dart';

const int _maxGeneratedOccurrences = 1000;
const int _maxHorizonDays = 365 * 2;

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

/// Soma (ou subtrai, com [days] negativo) dias a uma data em aritmética de
/// calendário (ano/mês/dia), em vez de `date.add(Duration(days: n))`. A
/// diferença importa: somar uma Duration soma tempo absoluto decorrido, o que
/// à volta de uma mudança de hora (DST) desloca a hora do resultado (ex.:
/// meia-noite passa a 01:00), o que por sua vez pode fazer o cursor "saltar"
/// ou "repetir" um dia em ciclos de geração de ocorrências. O construtor
/// [DateTime] com o dia fora do intervalo normaliza corretamente pelo
/// calendário, sem este desvio.
DateTime addCalendarDays(DateTime date, int days) {
  return DateTime(date.year, date.month, date.day + days, date.hour, date.minute, date.second, date.millisecond, date.microsecond);
}

/// Número de dias de calendário entre duas datas (independente de mudanças de
/// hora), usado em vez de `to.difference(from).inDays` para evitar o mesmo
/// desvio de tempo absoluto descrito em [addCalendarDays].
int calendarDaysBetween(DateTime from, DateTime to) {
  final utcFrom = DateTime.utc(from.year, from.month, from.day);
  final utcTo = DateTime.utc(to.year, to.month, to.day);
  return utcTo.difference(utcFrom).inDays;
}

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

DateTime startOfWeek(DateTime date) {
  final normalized = dateOnly(date);
  return addCalendarDays(normalized, -(normalized.weekday - 1));
}

DateTime endOfWeek(DateTime date) {
  final start = startOfWeek(date);
  return DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
}

DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

DateTime endOfMonth(DateTime date) {
  // dia 0 do mês seguinte = último dia do mês atual (normalização de calendário).
  final lastDay = DateTime(date.year, date.month + 1, 0);
  return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59, 999);
}

int weeksBetween(DateTime from, DateTime to) {
  final fromWeek = startOfWeek(from);
  final toWeek = startOfWeek(to);
  return calendarDaysBetween(fromWeek, toWeek) ~/ 7;
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
    cursor = addCalendarDays(cursor, 1);
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

/// Gera as ocorrências (data+hora) de um cliente entre `rangeStart` e
/// `rangeEnd` (inclusive) de acordo com a frequência de sessão escolhida —
/// sem aplicar [OccurrenceOverride]s (ver [generateResolvedOccurrencesInRange]
/// para isso). Uso interno; mantém-se privada para que a assinatura pública
/// [generateOccurrencesInRange] (que várias chamadas e testes de DST já
/// dependem devolver `List<DateTime>`) não precise de mudar.
List<DateTime> _generateRawOccurrences(
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
      cursor = addCalendarDays(cursor, 1);
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
    cursor = addCalendarDays(cursor, 1);
    guard++;
  }
  return occurrences;
}

/// Uma ocorrência já com [OccurrenceOverride]s aplicados: [scheduledFor] é a
/// data+hora efetiva (a original, ou a nova se tiver sido reagendada);
/// [originalScheduledFor] é sempre a data+hora que o horário fixo geraria.
class ResolvedOccurrence {
  final DateTime originalScheduledFor;
  final DateTime scheduledFor;
  const ResolvedOccurrence({required this.originalScheduledFor, required this.scheduledFor});
}

/// Como [generateOccurrencesInRange], mas já com as exceções pontuais do
/// cliente ([Client.occurrenceOverrides]) aplicadas: uma ocorrência cancelada
/// desaparece do seu dia original; uma ocorrência movida aparece na nova
/// data+hora (mesmo que o dia original esteja fora de `rangeStart`/`rangeEnd`,
/// desde que a nova data caia dentro do intervalo pedido).
List<ResolvedOccurrence> generateResolvedOccurrencesInRange(
  Client client, {
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  final raw = _generateRawOccurrences(client, rangeStart: rangeStart, rangeEnd: rangeEnd);
  if (client.occurrenceOverrides.isEmpty) {
    return [for (final occ in raw) ResolvedOccurrence(originalScheduledFor: occ, scheduledFor: occ)];
  }

  final effectiveRangeStart = dateOnly(rangeStart);
  final effectiveRangeEnd = dateOnly(rangeEnd);
  final overridesByDay = {for (final o in client.occurrenceOverrides) dateOnly(o.originalScheduledFor): o};

  final result = <ResolvedOccurrence>[];
  for (final occ in raw) {
    // Se existir um override para este dia (cancelada ou movida), a
    // ocorrência já não aparece no dia original — nunca as duas ao mesmo tempo.
    if (overridesByDay.containsKey(dateOnly(occ))) continue;
    result.add(ResolvedOccurrence(originalScheduledFor: occ, scheduledFor: occ));
  }

  // Ocorrências movidas PARA DENTRO deste intervalo, mesmo que o dia
  // original tenha ficado fora do intervalo bruto gerado acima.
  for (final override in client.occurrenceOverrides) {
    final moved = override.newDateTime;
    if (moved == null) continue; // cancelada: nada a injetar
    final movedDay = dateOnly(moved);
    if (!movedDay.isBefore(effectiveRangeStart) && !movedDay.isAfter(effectiveRangeEnd)) {
      result.add(ResolvedOccurrence(originalScheduledFor: override.originalScheduledFor, scheduledFor: moved));
    }
  }

  result.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  return result;
}

/// Gera todas as ocorrências (data+hora) de um cliente entre `rangeStart` e
/// `rangeEnd` (inclusive), já com exceções pontuais aplicadas — usado sempre
/// que só interessa a data+hora efetiva, não a distinção original/nova (ex.:
/// `_monthlyPeriodEnd`, que só quer saber o último dia de atividade do mês).
List<DateTime> generateOccurrencesInRange(
  Client client, {
  required DateTime rangeStart,
  required DateTime rangeEnd,
}) {
  return generateResolvedOccurrencesInRange(client, rangeStart: rangeStart, rangeEnd: rangeEnd)
      .map((r) => r.scheduledFor)
      .toList();
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
    final occurrences = generateResolvedOccurrencesInRange(client, rangeStart: now, rangeEnd: weekEnd);
    final registered = sessionsByClient[client.id] ?? [];
    for (final occurrence in occurrences) {
      final alreadyRegistered = registered.any((s) =>
          isSameDate(s.scheduledFor, occurrence.scheduledFor) &&
          s.scheduledFor.hour == occurrence.scheduledFor.hour &&
          s.scheduledFor.minute == occurrence.scheduledFor.minute);
      if (!alreadyRegistered) {
        result.add(PlannedOccurrence(
          client: client,
          scheduledFor: occurrence.scheduledFor,
          originalScheduledFor: occurrence.originalScheduledFor,
        ));
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
  final rangeStart = addCalendarDays(dateOnly(now), -7);
  final rangeEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
  final result = <PlannedOccurrence>[];
  for (final client in clients) {
    final occurrences = generateResolvedOccurrencesInRange(client, rangeStart: rangeStart, rangeEnd: rangeEnd);
    final registered = sessionsByClient[client.id] ?? [];
    for (final occurrence in occurrences) {
      final alreadyRegistered = registered.any((s) =>
          isSameDate(s.scheduledFor, occurrence.scheduledFor) &&
          s.scheduledFor.hour == occurrence.scheduledFor.hour &&
          s.scheduledFor.minute == occurrence.scheduledFor.minute);
      if (!alreadyRegistered) {
        result.add(PlannedOccurrence(
          client: client,
          scheduledFor: occurrence.scheduledFor,
          originalScheduledFor: occurrence.originalScheduledFor,
        ));
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

/// Acrescenta/substitui a exceção pontual de [updated] à lista — no máximo
/// uma por dia original (`originalScheduledFor`); uma segunda ação sobre o
/// mesmo dia substitui a anterior em vez de duplicar.
List<OccurrenceOverride> upsertOverride(List<OccurrenceOverride> existing, OccurrenceOverride updated) {
  final filtered = existing.where((o) => !isSameDate(o.originalScheduledFor, updated.originalScheduledFor)).toList();
  return [...filtered, updated];
}

/// Remove a exceção pontual (se existir) para o dia original indicado —
/// usado para "reverter ao horário normal".
List<OccurrenceOverride> removeOverrideForDay(List<OccurrenceOverride> existing, DateTime originalDay) {
  return existing.where((o) => !isSameDate(o.originalScheduledFor, originalDay)).toList();
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

  /// Identificador estável deste ciclo, único mesmo para dois ciclos Avulso
  /// do mesmo cliente no mesmo dia (que partilhariam periodStart/periodEnd) —
  /// usado pela UI (ex.: PaymentsTab) para controlar por ciclo, e não por
  /// dia, se o relatório já foi enviado.
  String get cycleId {
    if (frequency == PaymentType.avulso) return 'avulso:${sessions.single.id}';
    return '${periodStart.toIso8601String()}_${periodEnd.toIso8601String()}';
  }

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

/// Fim de um ciclo mensal: não é o último dia do calendário, mas o dia da
/// última ocorrência da atividade nesse mês (ex.: se as aulas são à
/// segunda-feira e a última segunda do mês é dia 27, o ciclo termina dia 27,
/// mesmo que o mês tenha mais dias a seguir), de acordo com o horário
/// *atual* do cliente.
///
/// [lastRegisteredSession] (a mais recente sessão já efetivamente registada
/// nesse mês) serve de garantia mínima: o ciclo nunca pode fechar antes
/// dela, mesmo que o horário atual (ex.: editado depois de sessões antigas
/// terem sido registadas noutro dia da semana, ou tê-lo esvaziado por
/// completo nesse mês) projete um fim mais cedo ou nenhuma ocorrência.
DateTime _monthlyPeriodEnd(Client client, DateTime monthAnchor, {required DateTime lastRegisteredSession}) {
  final monthStart = startOfMonth(monthAnchor);
  final calendarEnd = endOfMonth(monthAnchor);
  final occurrences = generateOccurrencesInRange(client, rangeStart: monthStart, rangeEnd: calendarEnd);

  final lastRegisteredDay = dateOnly(lastRegisteredSession);
  final lastRegisteredEnd = DateTime(lastRegisteredDay.year, lastRegisteredDay.month, lastRegisteredDay.day, 23, 59, 59, 999);
  if (occurrences.isEmpty) return lastRegisteredEnd;

  final lastOccurrenceDay = occurrences.map(dateOnly).reduce((a, b) => a.isAfter(b) ? a : b);
  final scheduleEnd = DateTime(lastOccurrenceDay.year, lastOccurrenceDay.month, lastOccurrenceDay.day, 23, 59, 59, 999);

  return scheduleEnd.isAfter(lastRegisteredEnd) ? scheduleEnd : lastRegisteredEnd;
}

/// Agrupa as sessões registadas de um cliente em ciclos de pagamento, de acordo
/// com a frequência de pagamento escolhida (Avulso = 1 sessão por ciclo,
/// Semanal = semana ISO, Mensal = mês civil, terminando no dia da última
/// ocorrência efetiva da atividade nesse mês).
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

  if (client.paymentType == PaymentType.semanal) {
    final groups = <String, PaymentCycleGroup>{};
    for (final session in sessions) {
      final periodStart = startOfWeek(session.scheduledFor);
      final periodEnd = dateOnly(endOfWeek(session.scheduledFor));
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

  // Mensal: primeiro agrupa TODAS as sessões por mês civil, só depois calcula
  // o fim de cada ciclo (uma vez por mês, já com todas as sessões desse mês
  // conhecidas) -- necessário para poder usar a última sessão efetivamente
  // registada como referência quando o horário atual do cliente já não
  // projeta nenhuma ocorrência nesse mês (ver _monthlyPeriodEnd).
  final byMonth = <DateTime, List<SessionRecord>>{};
  for (final session in sessions) {
    byMonth.putIfAbsent(startOfMonth(session.scheduledFor), () => []).add(session);
  }

  final result = byMonth.entries.map((entry) {
    final monthStart = entry.key;
    final monthSessions = entry.value;
    final lastRegistered = monthSessions.map((s) => s.scheduledFor).reduce((a, b) => a.isAfter(b) ? a : b);
    return PaymentCycleGroup(
      client: client,
      frequency: client.paymentType,
      periodStart: monthStart,
      periodEnd: _monthlyPeriodEnd(client, monthStart, lastRegisteredSession: lastRegistered),
      sessions: monthSessions,
    );
  }).toList();
  result.sort((a, b) => b.periodStart.compareTo(a.periodStart));
  return result;
}
