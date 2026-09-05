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
          onDelete: () {
            Navigator.of(context).pop();
            _deleteClient(client);
          },
        ),
      ),
    );
  }

  void _deleteClient(Client client) {
    final labels = getLabels(client.activityType, _language);
    setState(() {
      _clients.removeWhere((c) => c.id == client.id);
      _sessionsByClient.remove(client.id);
    });
    _bumpSessionsTick();
    _persist();

    showAppSnackBar(
      SnackBar(content: Text(s.clientDeletedSnackbar(labels.clientSingular, client.name))),
    );
  }

  Future<void> _openSchedule() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleScreen(
          activityType: _activityType,
          language: _language,
          clients: _clients,
          onClientUpdated: _updateClientFromSchedule,
        ),
      ),
    );
  }

  /// Reflete uma alteração feita no Horário (reagendar/cancelar/reverter uma
  /// única ocorrência) de volta na lista principal de clientes e persiste.
  void _updateClientFromSchedule(Client updated) {
    setState(() {
      final index = _clients.indexWhere((c) => c.id == updated.id);
      if (index >= 0) _clients[index] = updated;
    });
    _bumpSessionsTick();
    _persist();
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
      currentAppLanguage.value = result.language;
      _persist();
    }
  }

  void _registerOccurrence(PlannedOccurrence occurrence) {
    final client = occurrence.client;
    // Usa o tipo de atividade do próprio cliente (não o da área de trabalho
    // atual) para que o género gramatical/nomenclatura fique correto mesmo a
    // registar, a partir da vista "Todos", um cliente de outra atividade.
    final labels = getLabels(client.activityType, _language);
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

    showAppSnackBar(
      SnackBar(
        content: Text(s.registeredSnackbar(labels.sessionSingular, client.name, masculine: labels.sessionIsMasculine)),
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

    showAppSnackBar(
      SnackBar(content: Text(s.paymentMarkedPaidSnackbar(group.client.name, group.periodLabel(_language)))),
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

  /// Alunos/clientes da área de trabalho atual (Tipo de Atividade escolhido
  /// nas Definições). Alunos, Disciplinas e Pagamentos mostram só isto; o
  /// Dashboard continua a ver tudo, para dar a visão global do negócio.
  List<Client> get _workspaceClients => _clients.where((c) => c.activityType == _activityType).toList();

  /// Uma entrada por separador, na mesma ordem do `BottomNavigationBar`. Usa
  /// [IndexedStack] em vez de construir só o separador atual: assim os
  /// restantes ficam "offstage" mas montados, e não perdem o seu estado
  /// interno (ex.: o toggle "Nesta atividade/Todos", ou o registo de que um
  /// relatório de pagamento já foi enviado) sempre que se muda de separador.
  List<Widget> _buildTabs() {
    final now = DateTime.now();
    return [
      DashboardTab(
        key: const ValueKey('dashboard'),
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
      ),
      ClientsTab(
        key: const ValueKey('clients'),
        activityType: _activityType,
        language: _language,
        clients: _workspaceClients,
        allClients: _clients,
        sessionsByClient: _sessionsByClient,
        onAddClient: () => _openAddClientScreen(),
        onOpenClient: _openClientDetail,
        onOpenSettings: _openSettings,
      ),
      SubjectsTab(
        key: const ValueKey('subjects'),
        activityType: _activityType,
        language: _language,
        clients: _workspaceClients,
        allClients: _clients,
        sessionsByClient: _sessionsByClient,
        onOpenSettings: _openSettings,
      ),
      PaymentsTab(
        key: const ValueKey('payments'),
        activityType: _activityType,
        language: _language,
        clients: _workspaceClients,
        allClients: _clients,
        sessionsByClient: _sessionsByClient,
        onOpenClient: _openClientDetail,
        onMarkGroupPaid: _markGroupPaid,
        onClearGroup: _clearGroup,
        onOpenSettings: _openSettings,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(_activityType, _language);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _buildTabs()),
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
          BottomNavigationBarItem(icon: const Icon(Icons.people_outline), label: shortCompoundLabel(labels.clientPlural)),
          BottomNavigationBarItem(icon: const Icon(Icons.menu_book_outlined), label: shortCompoundLabel(labels.serviceTypeLabel)),
          BottomNavigationBarItem(icon: const Icon(Icons.payments_outlined), label: s.navPayments),
        ],
      ),
    );
  }
}
