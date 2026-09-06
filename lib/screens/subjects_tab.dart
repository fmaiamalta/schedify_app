import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../services/schedule_logic.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

class _SubjectSummary {
  final String name;
  final List<Client> clients;

  _SubjectSummary({required this.name, required this.clients});

  ActivityType get activityType => clients.first.activityType;
}

/// Só conta clientes ativos (ver [clientHasUpcomingSchedule]): uma
/// disciplina cujo último aluno terminou o horário deixa de aparecer aqui,
/// mesmo que o registo do aluno continue a existir em Alunos.
List<_SubjectSummary> _groupByName(
  List<Client> clients,
  Map<String, List<SessionRecord>> sessionsByClient,
  DateTime now,
) {
  final byName = <String, List<Client>>{};
  for (final client in clients) {
    if (!clientHasUpcomingSchedule(client, sessionsByClient[client.id] ?? const [], now)) continue;
    final name = client.serviceType.trim();
    if (name.isEmpty) continue;
    byName.putIfAbsent(name, () => []).add(client);
  }
  final summaries = byName.entries.map((e) => _SubjectSummary(name: e.key, clients: e.value)).toList();
  summaries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return summaries;
}

/// Separador "Aulas": lista apenas as disciplinas/atividades criadas (a partir
/// da disciplina indicada em cada aluno). Ao tocar numa, mostra o resumo dos
/// alunos inscritos nela.
class SubjectsTab extends StatefulWidget {
  final ActivityType activityType;
  final AppLanguage language;
  final List<Client> clients;
  final List<Client> allClients;
  final Map<String, List<SessionRecord>> sessionsByClient;
  final VoidCallback onOpenSettings;

  const SubjectsTab({
    super.key,
    required this.activityType,
    required this.language,
    required this.clients,
    required this.allClients,
    required this.sessionsByClient,
    required this.onOpenSettings,
  });

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(widget.activityType, widget.language);
    final s = AppStrings(widget.language);
    final showToggle = widget.allClients.length > widget.clients.length;

    // Nesta atividade: lista simples, já todas do mesmo tipo, por ordem alfabética.
    // Todos: agrupadas por atividade (ordem das Definições) e, dentro de cada uma, por ordem alfabética.
    final now = DateTime.now();
    final subjects = _showAll
        ? _groupByName(widget.allClients, widget.sessionsByClient, now)
        : _groupByName(widget.clients, widget.sessionsByClient, now);

    final totalCount = subjects.length;
    final title = _showAll ? s.allActivitiesTitle : labels.serviceTypeLabel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
            const SizedBox(height: 6),
            ScreenTitleRow(title: title, onOpenSettings: widget.onOpenSettings, settingsTooltip: s.settingsTitle),
            if (showToggle) ...[
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(s.thisActivityFilter)),
                  ButtonSegment(value: true, label: Text(s.allEnrolledFilter)),
                ],
                selected: {_showAll},
                showSelectedIcon: false,
                onSelectionChanged: (selection) => setState(() => _showAll = selection.first),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              s.subjectsCreated(totalCount, masculine: !_showAll && labels.serviceTypeIsMasculine),
              style: const TextStyle(fontSize: 16, color: AppColors.neutralSoft, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: subjects.isEmpty
                  ? Center(
                      child: Text(
                        s.noSubjectsYet(labels.serviceTypeLabel.toLowerCase(), labels.clientSingular.toLowerCase()),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.neutralSoft, height: 1.4),
                      ),
                    )
                  : _showAll
                      ? _GroupedSubjectList(subjects: subjects, labels: labels, s: s, language: widget.language, onOpen: _openSubjectDetail)
                      : _FlatSubjectList(subjects: subjects, labels: labels, s: s, onOpen: _openSubjectDetail),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubjectDetail(BuildContext context, _SubjectSummary subject, ActivityLabels labels, AppStrings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subject.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.neutralDark)),
              const SizedBox(height: 4),
              Text(
                s.enrolledCount(subject.clients.length, labels.clientSingular.toLowerCase(), labels.clientPlural.toLowerCase()),
                style: const TextStyle(color: AppColors.neutralSoft),
              ),
              const SizedBox(height: 16),
              ...([...subject.clients]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()))).map(
                (client) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: colorForActivityType(client.activityType)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(client.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        Text(_scheduleSummary(client, s), style: const TextStyle(color: AppColors.neutralSoft, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _scheduleSummary(Client client, AppStrings s) {
    if (client.slots.isEmpty) return s.dash;

    final sorted = [...client.slots]..sort((a, b) => a.weekday.compareTo(b.weekday));
    return sorted
        .map((slot) => '${s.weekdayShort(slot.weekday)} ${slot.time.hour.toString().padLeft(2, '0')}:${slot.time.minute.toString().padLeft(2, '0')}')
        .join(', ');
  }
}

typedef _OpenSubject = void Function(BuildContext context, _SubjectSummary subject, ActivityLabels labels, AppStrings s);

class _FlatSubjectList extends StatelessWidget {
  final List<_SubjectSummary> subjects;
  final ActivityLabels labels;
  final AppStrings s;
  final _OpenSubject onOpen;

  const _FlatSubjectList({required this.subjects, required this.labels, required this.s, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: subjects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _SubjectCard(subject: subjects[index], labels: labels, s: s, onOpen: onOpen),
    );
  }
}

class _GroupedSubjectList extends StatelessWidget {
  final List<_SubjectSummary> subjects;
  final ActivityLabels labels;
  final AppStrings s;
  final AppLanguage language;
  final _OpenSubject onOpen;

  const _GroupedSubjectList({
    required this.subjects,
    required this.labels,
    required this.s,
    required this.language,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    // Agrupa por atividade, na mesma ordem em que aparecem nas Definições.
    final groups = <ActivityType, List<_SubjectSummary>>{};
    for (final subject in subjects) {
      groups.putIfAbsent(subject.activityType, () => []).add(subject);
    }

    return ListView(
      children: [
        for (final type in ActivityType.values)
          if (groups[type] != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 4),
              child: Row(
                children: [
                  Icon(iconForActivityType(type), size: 16, color: colorForActivityType(type)),
                  const SizedBox(width: 8),
                  Text(
                    getLabels(type, language).areaName,
                    style: TextStyle(fontWeight: FontWeight.w700, color: colorForActivityType(type), fontSize: 13),
                  ),
                ],
              ),
            ),
            ...groups[type]!.map(
              (subject) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SubjectCard(subject: subject, labels: labels, s: s, onOpen: onOpen),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final _SubjectSummary subject;
  final ActivityLabels labels;
  final AppStrings s;
  final _OpenSubject onOpen;

  const _SubjectCard({required this.subject, required this.labels, required this.s, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final color = colorForActivityType(subject.activityType);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => onOpen(context, subject, labels, s),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
              child: Icon(iconForActivityType(subject.activityType), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.neutralDark)),
                  const SizedBox(height: 4),
                  Text(
                    s.enrolledCount(subject.clients.length, labels.clientSingular.toLowerCase(), labels.clientPlural.toLowerCase()),
                    style: const TextStyle(fontSize: 14, color: AppColors.neutralSoft),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.neutralSoft),
          ],
        ),
      ),
    );
  }
}
