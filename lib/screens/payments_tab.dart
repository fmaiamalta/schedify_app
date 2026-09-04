import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../services/report_service.dart';
import '../services/schedule_logic.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

class PaymentsTab extends StatefulWidget {
  final ActivityType activityType;
  final AppLanguage language;
  final List<Client> clients;
  final List<Client> allClients;
  final Map<String, List<SessionRecord>> sessionsByClient;
  final ValueChanged<Client> onOpenClient;
  final ValueChanged<PaymentCycleGroup> onMarkGroupPaid;
  final ValueChanged<PaymentCycleGroup> onClearGroup;
  final VoidCallback onOpenSettings;

  const PaymentsTab({
    super.key,
    required this.activityType,
    required this.language,
    required this.clients,
    required this.allClients,
    required this.sessionsByClient,
    required this.onOpenClient,
    required this.onMarkGroupPaid,
    required this.onClearGroup,
    required this.onOpenSettings,
  });

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

/// Identifica um ciclo de pagamento de forma estável (cliente + ciclo), para
/// saber se o relatório desse ciclo já foi enviado. Usa `cycleId` (não
/// periodStart diretamente) para que dois ciclos Avulso do mesmo cliente no
/// mesmo dia não colidam na mesma chave.
String _groupKey(PaymentCycleGroup group) => '${group.client.id}|${group.cycleId}';

class _PaymentsTabState extends State<PaymentsTab> {
  bool _showAll = false;
  final Set<String> _reportSentKeys = {};

  List<PaymentCycleGroup> _allGroups(List<Client> clients) {
    final groups = <PaymentCycleGroup>[];
    for (final client in clients) {
      final sessions = widget.sessionsByClient[client.id] ?? [];
      groups.addAll(computePaymentCycles(client, sessions));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(widget.activityType, widget.language);
    final s = AppStrings(widget.language);
    final now = DateTime.now();
    final showToggle = widget.allClients.length > widget.clients.length;
    final title = _showAll ? s.allPaymentsTitle : s.paymentsTitle;
    final allGroups = _allGroups(_showAll ? widget.allClients : widget.clients);

    final pending = allGroups.where((g) => g.hasPending).toList()
      ..sort((a, b) => b.periodStart.compareTo(a.periodStart));
    final completed = allGroups.where((g) => g.isFullyPaid).toList()
      ..sort((a, b) => b.periodStart.compareTo(a.periodStart));

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
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
              const SizedBox(height: 16),
              TabBar(
                labelColor: AppColors.brandBlue,
                unselectedLabelColor: AppColors.neutralSoft,
                indicatorColor: AppColors.brandBlue,
                tabs: [
                  Tab(text: s.pending),
                  Tab(text: s.completed),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _GroupList(
                      groups: pending,
                      labels: labels,
                      s: s,
                      now: now,
                      emptyText: s.noPendingPayments,
                      reportSentKeys: _reportSentKeys,
                      onReportSent: (group) => setState(() => _reportSentKeys.add(_groupKey(group))),
                      onOpenClient: widget.onOpenClient,
                      onMarkGroupPaid: widget.onMarkGroupPaid,
                      onClearGroup: null,
                    ),
                    _GroupList(
                      groups: completed,
                      labels: labels,
                      s: s,
                      now: now,
                      emptyText: s.noCompletedPayments,
                      reportSentKeys: _reportSentKeys,
                      onReportSent: (group) => setState(() => _reportSentKeys.add(_groupKey(group))),
                      onOpenClient: widget.onOpenClient,
                      onMarkGroupPaid: null,
                      onClearGroup: widget.onClearGroup,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupList extends StatelessWidget {
  final List<PaymentCycleGroup> groups;
  final ActivityLabels labels;
  final AppStrings s;
  final DateTime now;
  final String emptyText;
  final Set<String> reportSentKeys;
  final ValueChanged<PaymentCycleGroup> onReportSent;
  final ValueChanged<Client> onOpenClient;
  final ValueChanged<PaymentCycleGroup>? onMarkGroupPaid;
  final ValueChanged<PaymentCycleGroup>? onClearGroup;

  const _GroupList({
    required this.groups,
    required this.labels,
    required this.s,
    required this.now,
    required this.emptyText,
    required this.reportSentKeys,
    required this.onReportSent,
    required this.onOpenClient,
    required this.onMarkGroupPaid,
    required this.onClearGroup,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Center(child: Text(emptyText, style: const TextStyle(color: AppColors.neutralSoft)));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = groups[index];
        final closed = group.isClosed(now);
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onOpenClient(group.client),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.client.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.neutralDark)),
                          const SizedBox(height: 2),
                          Text(
                            group.client.serviceType.trim().isNotEmpty ? group.client.serviceType : labels.clientSingular,
                            style: const TextStyle(fontSize: 13, color: AppColors.neutralSoft),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onMarkGroupPaid != null)
                    closed
                        ? Checkbox(
                            value: false,
                            activeColor: AppColors.brandBlue,
                            onChanged: (_) => _confirmMarkPaid(context, group),
                          )
                        : Tooltip(
                            message: s.cycleStillAccumulating,
                            child: Icon(Icons.hourglass_bottom, color: AppColors.neutralSoft.withValues(alpha: 0.6), size: 20),
                          ),
                  if (onClearGroup != null)
                    IconButton(
                      onPressed: () => _confirmClear(context, group),
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.neutralSoft,
                      tooltip: s.clear,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(text: group.periodLabel(s.language)),
                  _Chip(text: '${group.totalSessions} ${labels.sessionPlural.toLowerCase()}'),
                  _Chip(
                    text: closed ? s.cycleClosed : s.accumulating,
                    background: closed ? AppColors.brandBlueSoft : AppColors.surfaceSoft,
                    color: closed ? AppColors.brandBlue : AppColors.neutralMedium,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${group.totalAmount.toStringAsFixed(2)}€',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.brandBlue),
                  ),
                  if (closed && onMarkGroupPaid != null)
                    OutlinedButton.icon(
                      onPressed: () => _openReport(context, group),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: Text(s.report),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmMarkPaid(BuildContext context, PaymentCycleGroup group) {
    final reportSent = reportSentKeys.contains(_groupKey(group));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.confirmPaymentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!reportSent) ...[
              Text(s.reportNotSentWarning, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            ],
            Text(s.confirmPaymentBody(group.client.name, group.periodLabel(s.language))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onMarkGroupPaid?.call(group);
            },
            child: Text(s.confirm),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, PaymentCycleGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.clearRecordTitle),
        content: Text(s.clearRecordBody(group.client.name, group.periodLabel(s.language))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(context).pop();
              onClearGroup?.call(group);
            },
            child: Text(s.clear),
          ),
        ],
      ),
    );
  }

  void _openReport(BuildContext context, PaymentCycleGroup group) {
    final message = buildReportMessage(client: group.client, cycle: group, strings: s);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.reportTitle(group.client.name), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.neutralDark)),
              const SizedBox(height: 4),
              Text(s.reportSummary(group.totalSessions, labels.sessionPlural.toLowerCase(), '${group.totalAmount.toStringAsFixed(2)}€'),
                  style: const TextStyle(color: AppColors.neutralSoft)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(16)),
                child: Text(message, style: const TextStyle(color: AppColors.neutralDark, height: 1.4)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: group.client.contactPhone.trim().isEmpty
                          ? null
                          : () async {
                              final sent = await sendViaWhatsApp(group.client.contactPhone, message);
                              if (sent) onReportSent(group);
                              if (context.mounted && !sent) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(s.whatsappOpenFailed)),
                                );
                              }
                            },
                      icon: const Icon(Icons.chat_outlined),
                      label: Text(s.whatsapp),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: group.client.contactEmail.trim().isEmpty
                          ? null
                          : () async {
                              final sent = await sendViaEmail(
                                group.client.contactEmail,
                                s.reportTitle(group.client.serviceType.isNotEmpty ? group.client.serviceType : group.client.name),
                                message,
                              );
                              if (sent) onReportSent(group);
                              if (context.mounted && !sent) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(s.emailOpenFailed)),
                                );
                              }
                            },
                      icon: const Icon(Icons.email_outlined),
                      label: Text(s.email),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.brandBlue, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color? background;
  final Color? color;

  const _Chip({required this.text, this.background, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? AppColors.neutralMedium),
      ),
    );
  }
}
