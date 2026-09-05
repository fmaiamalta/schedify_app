import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../services/schedule_logic.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

/// Ecrã "Horário": visualização em formato de calendário escolar, mostrando
/// apenas o nome do aluno/cliente e a disciplina/atividade em cada dia. Cada
/// ocorrência pode ser reagendada ou cancelada individualmente (ver
/// [OccurrenceOverride]), sem alterar o horário fixo do cliente.
class ScheduleScreen extends StatefulWidget {
  final ActivityType activityType;
  final AppLanguage language;
  final List<Client> clients;
  final ValueChanged<Client> onClientUpdated;

  const ScheduleScreen({
    super.key,
    required this.activityType,
    required this.language,
    required this.clients,
    required this.onClientUpdated,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _monthCursor;
  // Cópia local mutável: este ecrã é empurrado como rota separada, por isso
  // um setState no HomeShell não o reconstrói — precisa da sua própria cópia
  // para refletir uma alteração de imediato, propagando-a de volta via
  // widget.onClientUpdated para persistência.
  late List<Client> _clients;

  AppStrings get s => AppStrings(widget.language);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthCursor = DateTime(now.year, now.month, 1);
    _clients = [...widget.clients];
  }

  static String _formatDateTime(AppStrings s, DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${s.weekdayShort(value.weekday)} $day/$month • $hour:$minute';
  }

  Map<DateTime, List<PlannedOccurrence>> _occurrencesByDay() {
    final gridStart = _gridStart();
    final gridEnd = addCalendarDays(gridStart, 41);

    final map = <DateTime, List<PlannedOccurrence>>{};
    for (final client in _clients) {
      final resolved = generateResolvedOccurrencesInRange(client, rangeStart: gridStart, rangeEnd: gridEnd);
      for (final occurrence in resolved) {
        final key = dateOnly(occurrence.scheduledFor);
        map.putIfAbsent(key, () => []).add(PlannedOccurrence(
              client: client,
              scheduledFor: occurrence.scheduledFor,
              originalScheduledFor: occurrence.originalScheduledFor,
            ));
      }
      // Linhas "fantasma" para ocorrências canceladas, no seu dia original —
      // sem isto, cancelar seria uma ação sem forma de reverter mais tarde.
      for (final override in client.occurrenceOverrides) {
        if (!override.isCancelled) continue;
        final day = dateOnly(override.originalScheduledFor);
        if (day.isBefore(gridStart) || day.isAfter(gridEnd)) continue;
        map.putIfAbsent(day, () => []).add(PlannedOccurrence(
              client: client,
              scheduledFor: override.originalScheduledFor,
              originalScheduledFor: override.originalScheduledFor,
              isCancelled: true,
            ));
      }
    }
    for (final list in map.values) {
      list.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    }
    return map;
  }

  DateTime _gridStart() {
    final first = DateTime(_monthCursor.year, _monthCursor.month, 1);
    return addCalendarDays(first, -((first.weekday - 1) % 7));
  }

  void _applyClientUpdate(Client updated) {
    setState(() {
      final index = _clients.indexWhere((c) => c.id == updated.id);
      if (index >= 0) _clients[index] = updated;
    });
    widget.onClientUpdated(updated);
  }

  Future<void> _rescheduleOccurrence(PlannedOccurrence occurrence) async {
    final client = occurrence.client;
    final labels = getLabels(client.activityType, widget.language);
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: occurrence.scheduledFor,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await pickTimeWheel(context, TimeOfDay.fromDateTime(occurrence.scheduledFor), s);
    if (pickedTime == null || !mounted) return;

    final newDateTime = combineDateAndTime(pickedDate, pickedTime);
    final updatedClient = client.copyWith(
      occurrenceOverrides: upsertOverride(
        client.occurrenceOverrides,
        OccurrenceOverride(originalScheduledFor: occurrence.originalScheduledFor, newDateTime: newDateTime),
      ),
    );
    _applyClientUpdate(updatedClient);

    if (!mounted) return;
    showAppSnackBar(
      SnackBar(
        content: Text(s.occurrenceRescheduledSnackbar(
          labels.sessionSingular,
          client.name,
          _formatDateTime(s, newDateTime),
          masculine: labels.sessionIsMasculine,
        )),
      ),
    );
  }

  Future<void> _cancelOccurrence(PlannedOccurrence occurrence) async {
    final client = occurrence.client;
    final labels = getLabels(client.activityType, widget.language);
    final sessionLower = labels.sessionSingular.toLowerCase();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.confirmCancelOccurrenceTitle(sessionLower)),
        content: Text(s.confirmCancelOccurrenceBody(
          sessionLower,
          client.name,
          _formatDateTime(s, occurrence.scheduledFor),
          masculine: labels.sessionIsMasculine,
        )),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final updatedClient = client.copyWith(
      occurrenceOverrides: upsertOverride(
        client.occurrenceOverrides,
        OccurrenceOverride(originalScheduledFor: occurrence.originalScheduledFor, newDateTime: null),
      ),
    );
    _applyClientUpdate(updatedClient);

    if (!mounted) return;
    showAppSnackBar(
      SnackBar(content: Text(s.occurrenceCancelledSnackbar(labels.sessionSingular, client.name, masculine: labels.sessionIsMasculine))),
    );
  }

  void _revertOccurrence(PlannedOccurrence occurrence) {
    final client = occurrence.client;
    final updatedClient = client.copyWith(
      occurrenceOverrides: removeOverrideForDay(client.occurrenceOverrides, dateOnly(occurrence.originalScheduledFor)),
    );
    _applyClientUpdate(updatedClient);

    showAppSnackBar(
      SnackBar(content: Text(s.occurrenceRevertedSnackbar(client.name))),
    );
  }

  void _openOccurrenceActions(PlannedOccurrence occurrence) {
    final labels = getLabels(occurrence.client.activityType, widget.language);
    final sessionLower = labels.sessionSingular.toLowerCase();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    occurrence.client.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.neutralDark),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.event_repeat_outlined),
                  title: Text(s.rescheduleAction(sessionLower)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _rescheduleOccurrence(occurrence);
                  },
                ),
                if (!occurrence.isCancelled)
                  ListTile(
                    leading: const Icon(Icons.event_busy_outlined),
                    title: Text(s.cancelOccurrenceAction(sessionLower)),
                    onTap: () {
                      Navigator.of(context).pop();
                      _cancelOccurrence(occurrence);
                    },
                  ),
                if (occurrence.isMoved || occurrence.isCancelled)
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: Text(s.revertOccurrenceAction),
                    onTap: () {
                      Navigator.of(context).pop();
                      _revertOccurrence(occurrence);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDayBox(DateTime day, List<PlannedOccurrence> occurrences) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.weekdayShort(day.weekday)} ${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.neutralDark),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280, minWidth: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: occurrences.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final occurrence = occurrences[index];
                      final time = occurrence.scheduledFor;
                      final cancelled = occurrence.isCancelled;
                      return InkWell(
                        onTap: () {
                          // Fecha o diálogo do dia primeiro: a sua lista é uma
                          // cópia fixa e pode ficar desatualizada depois de editar.
                          Navigator.of(context).pop();
                          _openOccurrenceActions(occurrence);
                        },
                        child: Row(
                          children: [
                            Text(
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: cancelled ? AppColors.neutralSoft : AppColors.accentBlue,
                                decoration: cancelled ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    occurrence.client.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      decoration: cancelled ? TextDecoration.lineThrough : null,
                                      color: cancelled ? AppColors.neutralSoft : null,
                                    ),
                                  ),
                                  if (occurrence.client.serviceType.trim().isNotEmpty)
                                    Text(occurrence.client.serviceType, style: const TextStyle(fontSize: 12, color: AppColors.neutralSoft)),
                                ],
                              ),
                            ),
                            if (cancelled)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  s.cancelledBadgeLabel(masculine: getLabels(occurrence.client.activityType, widget.language).sessionIsMasculine),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutralMedium),
                                ),
                              )
                            else
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.neutralSoft),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.close)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final occurrencesByDay = _occurrencesByDay();
    final gridStart = _gridStart();
    final monthNames = s.monthNames;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        title: Text(s.schedule, style: const TextStyle(color: AppColors.neutralDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _monthCursor = DateTime(_monthCursor.year, _monthCursor.month - 1, 1);
                  }),
                ),
                SizedBox(
                  width: 180,
                  child: Text(
                    '${monthNames[_monthCursor.month - 1]} ${_monthCursor.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.neutralDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _monthCursor = DateTime(_monthCursor.year, _monthCursor.month + 1, 1);
                  }),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: s.weekdayShortHeader
                    .map((d) => Expanded(
                          child: Text(d, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.neutralSoft, fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  itemCount: 42,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                  itemBuilder: (context, index) {
                    final day = addCalendarDays(gridStart, index);
                    final inMonth = day.month == _monthCursor.month;
                    final occurrences = occurrencesByDay[day] ?? [];
                    final hasOccurrences = occurrences.isNotEmpty;

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: hasOccurrences ? () => _showDayBox(day, occurrences) : null,
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: hasOccurrences ? AppColors.brandBlueSoft : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: inMonth ? AppColors.neutralDark : AppColors.neutralSoft.withValues(alpha: 0.4),
                                fontWeight: hasOccurrences ? FontWeight.w800 : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (hasOccurrences)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: AppColors.brandBlue, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
