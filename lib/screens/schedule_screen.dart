import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../services/schedule_logic.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

/// Ecrã "Horário": grelha semanal ao estilo de um horário escolar — o eixo de
/// horas fixo à esquerda, um dia por coluna, e cada aula/sessão desenhada num
/// bloco posicionado e dimensionado pela hora de início e duração reais. Cada
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
  static const double _pixelsPerMinute = 1.4;
  static const double _dayColumnWidth = 118;
  static const double _hourAxisWidth = 46;
  static const double _dayHeaderHeight = 52;
  static const int _defaultStartHour = 8;
  static const int _defaultEndHour = 20;
  static const int _hourRangePaddingMinutes = 30;

  late DateTime _weekStart; // segunda-feira da semana em vista
  // Cópia local mutável: este ecrã é empurrado como rota separada, por isso
  // um setState no HomeShell não o reconstrói — precisa da sua própria cópia
  // para refletir uma alteração de imediato, propagando-a de volta via
  // widget.onClientUpdated para persistência.
  late List<Client> _clients;
  final _dayScrollController = ScrollController();

  AppStrings get s => AppStrings(widget.language);

  @override
  void initState() {
    super.initState();
    final today = dateOnly(DateTime.now());
    _weekStart = addCalendarDays(today, -((today.weekday - 1) % 7));
    _clients = [...widget.clients];
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTodayIfVisible());
  }

  @override
  void dispose() {
    _dayScrollController.dispose();
    super.dispose();
  }

  void _scrollToTodayIfVisible() {
    if (!_dayScrollController.hasClients) return;
    final today = dateOnly(DateTime.now());
    final offsetDays = today.difference(_weekStart).inDays;
    if (offsetDays < 0 || offsetDays > 6) return;
    final target = (offsetDays * _dayColumnWidth).clamp(
      0.0,
      _dayScrollController.position.maxScrollExtent,
    );
    _dayScrollController.jumpTo(target);
  }

  static String _formatDateTime(AppStrings s, DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${s.weekdayShort(value.weekday)} $day/$month • $hour:$minute';
  }

  Map<DateTime, List<PlannedOccurrence>> _occurrencesByDay() {
    final weekEnd = addCalendarDays(_weekStart, 6);

    final map = <DateTime, List<PlannedOccurrence>>{};
    for (final client in _clients) {
      final resolved = generateResolvedOccurrencesInRange(client, rangeStart: _weekStart, rangeEnd: weekEnd);
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
        if (day.isBefore(_weekStart) || day.isAfter(weekEnd)) continue;
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

  /// Intervalo de horas a mostrar na grelha, calculado a partir das
  /// ocorrências da semana em vista (com margem), ou o intervalo por omissão
  /// numa semana vazia — cada prestador de serviço pode trabalhar a horas
  /// muito diferentes, por isso não faz sentido um intervalo fixo.
  ({int startHour, int endHour}) _visibleHourRange(List<PlannedOccurrence> weekOccurrences) {
    if (weekOccurrences.isEmpty) {
      return (startHour: _defaultStartHour, endHour: _defaultEndHour);
    }
    var earliestMinutes = 24 * 60;
    var latestMinutes = 0;
    for (final occurrence in weekOccurrences) {
      final start = occurrence.scheduledFor.hour * 60 + occurrence.scheduledFor.minute;
      final end = start + occurrence.client.sessionDurationMinutes;
      if (start < earliestMinutes) earliestMinutes = start;
      if (end > latestMinutes) latestMinutes = end;
    }
    final startHour = ((earliestMinutes - _hourRangePaddingMinutes) / 60).floor().clamp(0, 23);
    final endHour = ((latestMinutes + _hourRangePaddingMinutes) / 60).ceil().clamp(startHour + 1, 24);
    return (startHour: startHour, endHour: endHour);
  }

  /// Atribui cada ocorrência de um dia a uma "faixa" (lane), para que
  /// ocorrências sobrepostas no tempo fiquem lado a lado em vez de uma por
  /// cima da outra — caso raro (o mesmo prestador normalmente não tem duas
  /// sessões em simultâneo), mas sem isto ficariam ilegíveis se acontecesse.
  Map<PlannedOccurrence, int> _assignLanes(List<PlannedOccurrence> dayOccurrences) {
    final sorted = [...dayOccurrences]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    final laneEndMinutes = <int>[];
    final lanes = <PlannedOccurrence, int>{};
    for (final occurrence in sorted) {
      final start = occurrence.scheduledFor.hour * 60 + occurrence.scheduledFor.minute;
      final end = start + occurrence.client.sessionDurationMinutes;
      var assigned = -1;
      for (var i = 0; i < laneEndMinutes.length; i++) {
        if (laneEndMinutes[i] <= start) {
          assigned = i;
          break;
        }
      }
      if (assigned == -1) {
        assigned = laneEndMinutes.length;
        laneEndMinutes.add(end);
      } else {
        laneEndMinutes[assigned] = end;
      }
      lanes[occurrence] = assigned;
    }
    return lanes;
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

  Widget _buildHourAxis(int startHour, int endHour) {
    return Column(
      children: [
        const SizedBox(height: _dayHeaderHeight),
        for (var hour = startHour; hour < endHour; hour++)
          SizedBox(
            height: 60 * _pixelsPerMinute,
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutralSoft),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDayHeader(DateTime day) {
    final isToday = day == dateOnly(DateTime.now());
    return SizedBox(
      height: _dayHeaderHeight,
      child: Center(
        child: Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isToday ? AppColors.brandBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.weekdayShort(day.weekday),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isToday ? Colors.white70 : AppColors.neutralSoft,
                ),
              ),
              Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isToday ? Colors.white : AppColors.neutralDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayColumn(DateTime day, List<PlannedOccurrence> occurrences, int startHour, double totalHeight) {
    final lanes = _assignLanes(occurrences);
    final laneCount = lanes.values.isEmpty ? 1 : (lanes.values.reduce((a, b) => a > b ? a : b) + 1);
    const horizontalPadding = 3.0;
    final laneWidth = (_dayColumnWidth - horizontalPadding * 2) / laneCount;

    return SizedBox(
      width: _dayColumnWidth,
      child: Column(
        children: [
          _buildDayHeader(day),
          SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                for (final occurrence in occurrences)
                  Positioned(
                    top: (occurrence.scheduledFor.hour * 60 + occurrence.scheduledFor.minute - startHour * 60) * _pixelsPerMinute,
                    left: horizontalPadding + laneWidth * lanes[occurrence]!,
                    width: laneWidth,
                    height: occurrence.client.sessionDurationMinutes * _pixelsPerMinute,
                    child: _OccurrenceBlock(
                      occurrence: occurrence,
                      color: colorForActivityType(occurrence.client.activityType),
                      onTap: () => _openOccurrenceActions(occurrence),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final occurrencesByDay = _occurrencesByDay();
    final weekOccurrences = occurrencesByDay.values.expand((list) => list).toList();
    final hourRange = _visibleHourRange(weekOccurrences);
    final totalHeight = (hourRange.endHour - hourRange.startHour) * 60 * _pixelsPerMinute;
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
                    _weekStart = addCalendarDays(_weekStart, -7);
                  }),
                ),
                SizedBox(
                  width: 180,
                  child: Text(
                    '${monthNames[_weekStart.month - 1]} ${_weekStart.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.neutralDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _weekStart = addCalendarDays(_weekStart, 7);
                  }),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _hourAxisWidth,
                      child: _buildHourAxis(hourRange.startHour, hourRange.endHour),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _dayScrollController,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < 7; i++)
                              _buildDayColumn(
                                addCalendarDays(_weekStart, i),
                                occurrencesByDay[addCalendarDays(_weekStart, i)] ?? const [],
                                hourRange.startHour,
                                totalHeight,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OccurrenceBlock extends StatelessWidget {
  final PlannedOccurrence occurrence;
  final Color color;
  final VoidCallback onTap;

  const _OccurrenceBlock({required this.occurrence, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cancelled = occurrence.isCancelled;
    final client = occurrence.client;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: cancelled ? Colors.transparent : color.withValues(alpha: 0.16),
            border: Border.all(color: cancelled ? AppColors.neutralSoft : color, width: cancelled ? 1 : 1.4),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                client.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cancelled ? AppColors.neutralSoft : AppColors.neutralDark,
                  decoration: cancelled ? TextDecoration.lineThrough : null,
                ),
              ),
              if (client.serviceType.trim().isNotEmpty)
                Text(
                  client.serviceType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: cancelled ? AppColors.neutralSoft : AppColors.neutralMedium,
                    decoration: cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
