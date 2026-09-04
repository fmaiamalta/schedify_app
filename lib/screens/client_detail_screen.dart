import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

class ClientDetailScreen extends StatelessWidget {
  final Client client;
  final ActivityType activityType;
  final AppLanguage language;
  final List<SessionRecord> sessions;
  final Future<void> Function() onEdit;

  const ClientDetailScreen({
    super.key,
    required this.client,
    required this.activityType,
    required this.language,
    required this.sessions,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType, language);
    final s = AppStrings(language);
    final sortedSessions = [...sessions]..sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          client.name,
          style: const TextStyle(color: AppColors.neutralDark, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: AppColors.brandBlue),
            label: Text(s.edit, style: const TextStyle(color: AppColors.brandBlue)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ListView(
            children: [
              Text(
                labels.clientSingular,
                style: const TextStyle(fontSize: 16, color: AppColors.neutralSoft, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              SectionTitle(title: s.info),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailLine(label: s.nameLabel, value: _orDash(client.name, s)),
                    const SizedBox(height: 10),
                    DetailLine(label: labels.serviceTypeLabel, value: _orDash(client.serviceType, s)),
                    const SizedBox(height: 10),
                    DetailLine(label: s.emailLabel, value: _orDash(client.contactEmail, s)),
                    const SizedBox(height: 10),
                    DetailLine(label: s.phoneLabel, value: _orDash(client.contactPhone, s)),
                    const SizedBox(height: 10),
                    DetailLine(label: s.notesLabel, value: _orDash(client.notes, s)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(title: s.sessionConfigSection(labels.sessionSingular.toLowerCase(), masculine: labels.sessionIsMasculine)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailLine(label: s.durationLabel, value: '${client.sessionDurationMinutes} ${s.minutesAbbrev}'),
                    const SizedBox(height: 10),
                    DetailLine(label: s.frequencyLabel, value: sessionFrequencyLabel(client.sessionFrequency, language)),
                    const SizedBox(height: 10),
                    DetailLine(
                      label: s.scheduleLabel,
                      value: client.slots.isEmpty
                          ? s.dash
                          : client.slots.map((slot) => '${s.weekdayFull(slot.weekday)} ${slot.time.format(context)}').join(', '),
                    ),
                    const SizedBox(height: 10),
                    DetailLine(label: s.startLabel, value: _formatDate(client.startDate)),
                    const SizedBox(height: 10),
                    DetailLine(label: s.endLabel, value: client.endDate != null ? _formatDate(client.endDate!) : s.noEndDateLabel),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(title: s.paymentConfigSection),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailLine(
                      label: s.valueLabel,
                      value: '${client.hourlyRate.toStringAsFixed(2)}€ (${client.rateType == RateType.total ? s.totalOption : s.perHourOption})',
                    ),
                    const SizedBox(height: 10),
                    DetailLine(label: s.vatLabel, value: client.hasVat ? s.yes : s.no),
                    const SizedBox(height: 10),
                    DetailLine(label: s.paymentLabel, value: paymentTypeLabel(client.paymentType, language)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(title: labels.sessionPlural),
              const SizedBox(height: 14),
              if (sortedSessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(22)),
                  child: Text(
                    s.noneRecordedYet(labels.sessionPlural.toLowerCase(), masculine: labels.sessionIsMasculine),
                    style: const TextStyle(fontSize: 14, color: AppColors.neutralSoft),
                  ),
                )
              else
                ...sortedSessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SessionMiniCard(session: session, s: s, masculine: labels.sessionIsMasculine),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _orDash(String value, AppStrings s) => value.trim().isEmpty ? s.dash : value;

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}

class _SessionMiniCard extends StatelessWidget {
  final SessionRecord session;
  final AppStrings s;
  final bool masculine;

  const _SessionMiniCard({required this.session, required this.s, this.masculine = false});

  @override
  Widget build(BuildContext context) {
    final scheduled = session.scheduledFor;
    final day = scheduled.day.toString().padLeft(2, '0');
    final month = scheduled.month.toString().padLeft(2, '0');
    final hour = scheduled.hour.toString().padLeft(2, '0');
    final minute = scheduled.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$day/$month • $hour:$minute\n${session.durationMinutes} ${s.minutesAbbrev} • ${session.amount.toStringAsFixed(2)}€',
              style: const TextStyle(fontSize: 14, color: AppColors.neutralSoft, height: 1.4),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: session.isPaid ? Colors.green.withValues(alpha: 0.12) : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.isPaid ? s.paidLabel(masculine: masculine) : s.pendingBadge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: session.isPaid ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
