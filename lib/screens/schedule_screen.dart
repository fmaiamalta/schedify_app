import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../services/schedule_logic.dart';
import '../theme.dart';

/// Ecrã "Horário": visualização em formato de calendário escolar, mostrando
/// apenas o nome do aluno/cliente e a disciplina/atividade em cada dia.
class ScheduleScreen extends StatefulWidget {
  final ActivityType activityType;
  final AppLanguage language;
  final List<Client> clients;

  const ScheduleScreen({super.key, required this.activityType, required this.language, required this.clients});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _monthCursor;

  AppStrings get s => AppStrings(widget.language);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthCursor = DateTime(now.year, now.month, 1);
  }

  Map<DateTime, List<PlannedOccurrence>> _occurrencesByDay() {
    final gridStart = _gridStart();
    final gridEnd = gridStart.add(const Duration(days: 41));

    final map = <DateTime, List<PlannedOccurrence>>{};
    for (final client in widget.clients) {
      final occurrences = generateOccurrencesInRange(client, rangeStart: gridStart, rangeEnd: gridEnd);
      for (final occurrence in occurrences) {
        final key = dateOnly(occurrence);
        map.putIfAbsent(key, () => []).add(PlannedOccurrence(client: client, scheduledFor: occurrence));
      }
    }
    for (final list in map.values) {
      list.sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
    }
    return map;
  }

  DateTime _gridStart() {
    final first = DateTime(_monthCursor.year, _monthCursor.month, 1);
    return first.subtract(Duration(days: (first.weekday - 1) % 7));
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
                      return Row(
                        children: [
                          Text(
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.accentBlue),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(occurrence.client.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                if (occurrence.client.serviceType.trim().isNotEmpty)
                                  Text(occurrence.client.serviceType, style: const TextStyle(fontSize: 12, color: AppColors.neutralSoft)),
                              ],
                            ),
                          ),
                        ],
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
                    final day = gridStart.add(Duration(days: index));
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
