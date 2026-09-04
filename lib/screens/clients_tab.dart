import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

class ClientsTab extends StatefulWidget {
  final ActivityType activityType;
  final AppLanguage language;
  final List<Client> clients;
  final List<Client> allClients;
  final VoidCallback onAddClient;
  final ValueChanged<Client> onOpenClient;
  final VoidCallback onOpenSettings;

  const ClientsTab({
    super.key,
    required this.activityType,
    required this.language,
    required this.clients,
    required this.allClients,
    required this.onAddClient,
    required this.onOpenClient,
    required this.onOpenSettings,
  });

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(widget.activityType, widget.language);
    final s = AppStrings(widget.language);
    final showToggle = widget.allClients.length > widget.clients.length;
    final displayed = [...(_showAll ? widget.allClients : widget.clients)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final title = _showAll ? s.allEnrolledTitle : labels.clientPlural;

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.countRegistered(displayed.length),
                    style: const TextStyle(fontSize: 16, color: AppColors.neutralSoft, fontWeight: FontWeight.w500),
                  ),
                ),
                if (displayed.isNotEmpty)
                  FilledButton.icon(
                    onPressed: widget.onAddClient,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(s.newLabel(labels.clientSingular)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: displayed.isEmpty
                  ? _EmptyClientsState(activityType: widget.activityType, language: widget.language, onAddClient: widget.onAddClient)
                  : ListView.separated(
                      itemCount: displayed.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final client = displayed[index];
                        final subtitle = client.serviceType.trim().isNotEmpty ? client.serviceType : client.contactEmail;
                        return ClientCard(
                          name: client.name,
                          subtitle: subtitle,
                          onTap: () => widget.onOpenClient(client),
                          accentColor: colorForActivityType(client.activityType),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyClientsState extends StatelessWidget {
  final ActivityType activityType;
  final AppLanguage language;
  final VoidCallback onAddClient;

  const _EmptyClientsState({required this.activityType, required this.language, required this.onAddClient});

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType, language);
    final s = AppStrings(language);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.brandBlueSoft, borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.group_outlined, size: 34, color: AppColors.brandBlue),
            ),
            const SizedBox(height: 18),
            Text(
              s.noneRegisteredYet(labels.clientPlural.toLowerCase()),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.neutralDark),
            ),
            const SizedBox(height: 10),
            Text(
              s.startByAdding(labels.clientSingular.toLowerCase()),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.neutralSoft, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddClient,
              icon: const Icon(Icons.add),
              label: Text(s.newLabel(labels.clientSingular)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
