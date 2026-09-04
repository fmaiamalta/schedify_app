import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../services/schedule_logic.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import 'register_screen.dart';

class DashboardTab extends StatelessWidget {
  final ActivityType activityType;
  final AppLanguage language;
  final List<ActivityStats> activityStats;
  final List<PlannedOccurrence> upcomingThisWeek;
  final List<PlannedOccurrence> registerableNow;
  final ValueListenable<int> sessionsTick;
  final List<PlannedOccurrence> Function() registerableNowProvider;
  final VoidCallback onAddClient;
  final VoidCallback onOpenSchedule;
  final VoidCallback onOpenSettings;
  final ValueChanged<PlannedOccurrence> onRegisterOccurrence;

  const DashboardTab({
    super.key,
    required this.activityType,
    required this.language,
    required this.activityStats,
    required this.upcomingThisWeek,
    required this.registerableNow,
    required this.sessionsTick,
    required this.registerableNowProvider,
    required this.onAddClient,
    required this.onOpenSchedule,
    required this.onOpenSettings,
    required this.onRegisterOccurrence,
  });

  void _openRegisterScreen(BuildContext context, AppStrings s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterScreen(
          strings: s,
          sessionsTick: sessionsTick,
          occurrencesProvider: registerableNowProvider,
          onRegisterOccurrence: onRegisterOccurrence,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType, language);
    final s = AppStrings(language);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: ListView(
          children: [
            const AppHeader(),
            const SizedBox(height: 6),
            ScreenTitleRow(title: s.dashboard, onOpenSettings: onOpenSettings, settingsTooltip: s.settingsTitle),
            const SizedBox(height: 8),
            Text(
              labels.areaName,
              style: const TextStyle(fontSize: 16, color: AppColors.neutralSoft, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            SectionTitle(title: s.quickActions),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.person_add_alt_1_outlined,
                    label: s.newLabel(labels.clientSingular),
                    iconColor: AppColors.brandBlue,
                    textColor: AppColors.brandBlue,
                    background: AppColors.brandBlueSoft,
                    onTap: onAddClient,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.check_circle_outline,
                    label: s.registerLabel(labels.sessionSingular),
                    iconColor: AppColors.brandGreen,
                    textColor: AppColors.brandGreen,
                    background: AppColors.brandGreenSoft,
                    onTap: () => _openRegisterScreen(context, s),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.calendar_month_outlined,
                    label: s.schedule,
                    iconColor: AppColors.neutralMedium,
                    textColor: AppColors.neutralMedium,
                    background: AppColors.surfaceSoft,
                    onTap: onOpenSchedule,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionTitle(title: s.upcomingThisWeek(labels.sessionPlural)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(20)),
              child: upcomingThisWeek.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        s.noneScheduledThisWeek(labels.sessionPlural.toLowerCase()),
                        style: const TextStyle(fontSize: 15, color: AppColors.neutralSoft, height: 1.4),
                      ),
                    )
                  : Column(
                      children: upcomingThisWeek
                          .map(
                            (occurrence) => ListTile(
                              leading: const Icon(Icons.event_outlined, color: AppColors.accentBlue),
                              title: Text(occurrence.client.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${s.weekdayShort(occurrence.scheduledFor.weekday)} • ${_formatDateTime(occurrence.scheduledFor)}'
                                '${occurrence.client.serviceType.trim().isNotEmpty ? ' • ${occurrence.client.serviceType}' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 28),
            SectionTitle(title: s.statistics),
            const SizedBox(height: 14),
            if (activityStats.isEmpty)
              InfoTile(
                icon: Icons.bar_chart_outlined,
                title: s.statistics,
                subtitle: s.registeredCountLabel(0),
              )
            else
              ...activityStats.map((stat) {
                final statLabels = getLabels(stat.activityType, language);
                final color = colorForActivityType(stat.activityType);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(18)),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Icon(iconForActivityType(stat.activityType), color: color),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(statLabels.areaName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.neutralDark)),
                              const SizedBox(height: 2),
                              Text(
                                s.registeredCountLabel(stat.registeredCount),
                                style: const TextStyle(fontSize: 13, color: AppColors.neutralSoft),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${stat.receivedAmount.toStringAsFixed(2)}€',
                              style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16),
                            ),
                            Text(
                              s.paymentsReceived,
                              style: const TextStyle(fontSize: 11, color: AppColors.neutralSoft),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month • $hour:$minute';
  }
}
