import 'package:flutter/material.dart';
import 'i18n/app_strings.dart';
import 'models.dart';
import 'screens/add_client_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/clients_tab.dart';
import 'screens/dashboard_tab.dart';
import 'screens/payments_tab.dart';
import 'screens/schedule_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/subjects_tab.dart';
import 'services/schedule_logic.dart';
import 'services/storage_service.dart';
import 'theme.dart';

class HomeShell extends StatefulWidget {
  final ActivityType initialActivityType;
  final AppLanguage initialLanguage;
  final List<Client> initialClients;
  final Map<String, List<SessionRecord>> initialSessions;

  const HomeShell({
    super.key,
    required this.initialActivityType,
    this.initialLanguage = AppLanguage.pt,
    this.initialClients = const [],
    this.initialSessions = const {},
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _storage = StorageService();

  // Incrementado sempre que _clients/_sessionsByClient mudam, para que ecrãs
  // já empurrados (ex.: RegisterScreen) saibam que devem recalcular os seus
  // dados a partir da fonte de verdade, em vez de ficarem com uma cópia
  // desatualizada (ex.: depois de "Anular" um registo).
  final _sessionsTick = ValueNotifier<int>(0);

  int _currentIndex = 0;
  late ActivityType _activityType;
  late AppLanguage _language;
  late List<Client> _clients;
  late Map<String, List<SessionRecord>> _sessionsByClient;

  AppStrings get s => AppStrings(_language);

  @override
  void initState() {
    super.initState();
    _activityType = widget.initialActivityType;
    _language = widget.initialLanguage;
    _clients = [...widget.initialClients];
    _sessionsByClient = {for (final entry in widget.initialSessions.entries) entry.key: [...entry.value]};
  }

  @override
  void dispose() {
    _sessionsTick.dispose();
    super.dispose();
  }

  void _bumpSessionsTick() => _sessionsTick.value++;

  void _persist() {
    _storage.save(
      activityType: _activityType,
      language: _language,
      clients: _clients,
      sessionsByClient: _sessionsByClient,
    );
  }

  Future<void> _openAddClientScreen({Client? existing}) async {
    final result = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => AddClientScreen(activityType: _activityType, language: _language, existingClient: existing),
      ),
    );
    if (result == null) return;

    setState(() {
      final index = _clients.indexWhere((c) => c.id == result.id);
      if (index >= 0) {
        _clients[index] = result;
      } else {
        _clients.add(result);
        _sessionsByClient[result.id] = [];
      }
    });
    _bumpSessionsTick();
    _persist();
  }

  Future<void> _openClientDetail(Client client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientDetailScreen(
          client: client,
          activityType: client.activityType,
          language: _language,
          sessions: _sessionsByClient[client.id] ?? [],
          onEdit: () async {
            Navigator.of(context).pop();
            await _openAddClientScreen(existing: client);
          },
        ),
      ),
    );
  }

  Future<void> _openSchedule() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScheduleScreen(activityType: _activityType, language: _language, clients: _clients)),
    );
  }

  Future<void> _openSettings() async {
    final result = await Navigator.of(context).push<SettingsResult>(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(currentActivityType: _activityType, currentLanguage: _language),
      ),
    );
    if (result != null) {
      setState(() {
        _activityType = result.activityType;
        _language = result.language;
      });
      _persist();
    }
  }

  void _registerOccurrence(PlannedOccurrence occurrence) {
    final client = occurrence.client;
    final labels = getLabels(_activityType, _language);
    final amount = calculateSessionAmount(client, client.sessionDurationMinutes);

    final session = SessionRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      clientId: client.id,
      registeredAt: DateTime.now(),
      scheduledFor: occurrence.scheduledFor,
      durationMinutes: client.sessionDurationMinutes,
      amount: amount,
    );

    setState(() {
      _sessionsByClient.putIfAbsent(client.id, () => []);
      _sessionsByClient[client.id]!.add(session);
    });
    _bumpSessionsTick();
    _persist();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.registeredSnackbar(labels.sessionSingular, client.name)),
        action: SnackBarAction(label: s.undo, onPressed: () => _removeSession(client.id, session.id)),
      ),
    );
  }

  void _removeSession(String clientId, String sessionId) {
    setState(() {
      _sessionsByClient[clientId]?.removeWhere((s) => s.id == sessionId);
    });
    _bumpSessionsTick();
    _persist();
  }

  void _markGroupPaid(PaymentCycleGroup group) {
    final sessionIds = group.sessions.map((s) => s.id).toSet();
    setState(() {
      final sessions = _sessionsByClient[group.client.id];
      if (sessions == null) return;
      for (var i = 0; i < sessions.length; i++) {
        if (sessionIds.contains(sessions[i].id)) {
          sessions[i] = sessions[i].copyWith(isPaid: true);
        }
      }
    });
    _bumpSessionsTick();
    _persist();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.confirmPaymentBody(group.client.name, group.periodLabel(_language)))),
    );
  }

  void _clearGroup(PaymentCycleGroup group) {
    final sessionIds = group.sessions.map((s) => s.id).toSet();
    setState(() {
      _sessionsByClient[group.client.id]?.removeWhere((s) => sessionIds.contains(s.id));
    });
    _bumpSessionsTick();
    _persist();
  }

  /// Usa só a primeira palavra/segmento de nomenclaturas compostas (ex.:
  /// "Alunos/Formandos" → "Alunos", "Especialidade / Tipo de consulta" →
  /// "Especialidade") para que os rótulos do menu inferior tenham sempre um
  /// comprimento semelhante e os ícones fiquem uniformemente espaçados.
  String _shortNavLabel(String label) => label.split('/').first.trim();

  /// Alunos/clientes da área de trabalho atual (Tipo de Atividade escolhido
  /// nas Definições). Alunos, Disciplinas e Pagamentos mostram só isto; o
  /// Dashboard continua a ver tudo, para dar a visão global do negócio.
  List<Client> get _workspaceClients => _clients.where((c) => c.activityType == _activityType).toList();

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        final now = DateTime.now();
        return DashboardTab(
          activityType: _activityType,
          language: _language,
          activityStats: statsByActivity(_clients, _sessionsByClient),
          upcomingThisWeek: upcomingThisWeek(_clients, _sessionsByClient, now),
          registerableNow: registerableNow(_clients, _sessionsByClient, now),
          sessionsTick: _sessionsTick,
          registerableNowProvider: () => registerableNow(_clients, _sessionsByClient, DateTime.now()),
          onAddClient: () => _openAddClientScreen(),
          onOpenSchedule: _openSchedule,
          onOpenSettings: _openSettings,
          onRegisterOccurrence: _registerOccurrence,
        );
      case 1:
        return ClientsTab(
          activityType: _activityType,
          language: _language,
          clients: _workspaceClients,
          allClients: _clients,
          onAddClient: () => _openAddClientScreen(),
          onOpenClient: _openClientDetail,
          onOpenSettings: _openSettings,
        );
      case 2:
        return SubjectsTab(
          activityType: _activityType,
          language: _language,
          clients: _workspaceClients,
          allClients: _clients,
          onOpenSettings: _openSettings,
        );
      case 3:
        return PaymentsTab(
          activityType: _activityType,
          language: _language,
          clients: _workspaceClients,
          sessionsByClient: _sessionsByClient,
          onOpenClient: _openClientDetail,
          onMarkGroupPaid: _markGroupPaid,
          onClearGroup: _clearGroup,
          onOpenSettings: _openSettings,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(_activityType, _language);

    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.brandBlue,
        unselectedItemColor: AppColors.neutralSoft,
        backgroundColor: AppColors.surfaceWhite,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.dashboard_outlined), label: s.navHome),
          BottomNavigationBarItem(icon: const Icon(Icons.people_outline), label: _shortNavLabel(labels.clientPlural)),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book_outlined), label: _shortNavLabel(labels.serviceTypeLabel)),
          BottomNavigationBarItem(icon: const Icon(Icons.payments_outlined), label: s.navPayments),
        ],
      ),
    );
  }
}
