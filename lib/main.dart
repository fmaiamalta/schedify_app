import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SchedifyApp());
}

class SchedifyApp extends StatelessWidget {
  const SchedifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Schedify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B2A7A),
        ),
        useMaterial3: true,
      ),
      home: const ActivitySelectionScreen(),
    );
  }
}

enum ActivityType {
  education,
  fitness,
  health,
  otherServices,
}

enum PaymentType {
  perSession,
  monthly,
  oneOff,
}

class ActivityLabels {
  final String areaName;
  final String clientSingular;
  final String clientPlural;
  final String sessionSingular;
  final String sessionPlural;
  final String serviceTypeLabel;
  final String durationLabel;
  final String frequencyLabel;
  final String rateLabel;

  const ActivityLabels({
    required this.areaName,
    required this.clientSingular,
    required this.clientPlural,
    required this.sessionSingular,
    required this.sessionPlural,
    required this.serviceTypeLabel,
    required this.durationLabel,
    required this.frequencyLabel,
    required this.rateLabel,
  });
}

ActivityLabels getLabels(ActivityType type) {
  switch (type) {
    case ActivityType.education:
      return const ActivityLabels(
        areaName: 'Educação',
        clientSingular: 'Aluno/Formando',
        clientPlural: 'Alunos/Formandos',
        sessionSingular: 'Aula',
        sessionPlural: 'Aulas',
        serviceTypeLabel: 'Disciplina',
        durationLabel: 'Duração da aula',
        frequencyLabel: 'Frequência da aula',
        rateLabel: 'Valor por hora (€)',
      );
    case ActivityType.fitness:
      return const ActivityLabels(
        areaName: 'Fitness',
        clientSingular: 'Aluno',
        clientPlural: 'Alunos',
        sessionSingular: 'Treino',
        sessionPlural: 'Treinos',
        serviceTypeLabel: 'Modalidade / Serviço',
        durationLabel: 'Duração do treino',
        frequencyLabel: 'Frequência do treino',
        rateLabel: 'Valor por hora (€)',
      );
    case ActivityType.health:
      return const ActivityLabels(
        areaName: 'Saúde',
        clientSingular: 'Utente/Paciente',
        clientPlural: 'Utentes/Pacientes',
        sessionSingular: 'Consulta',
        sessionPlural: 'Consultas',
        serviceTypeLabel: 'Especialidade / Tipo de consulta',
        durationLabel: 'Duração da consulta',
        frequencyLabel: 'Frequência da consulta',
        rateLabel: 'Valor da consulta (€)',
      );
    case ActivityType.otherServices:
      return const ActivityLabels(
        areaName: 'Outros Serviços',
        clientSingular: 'Cliente',
        clientPlural: 'Clientes',
        sessionSingular: 'Sessão',
        sessionPlural: 'Sessões',
        serviceTypeLabel: 'Serviço',
        durationLabel: 'Duração da sessão',
        frequencyLabel: 'Frequência da sessão',
        rateLabel: 'Valor por hora (€)',
      );
  }
}

class AppColors {
  static const Color brandBlue = Color(0xFF0B2A7A);
  static const Color brandBlueSoft = Color(0xFFEAF0FB);

  static const Color accentBlue = Color(0xFF2F5D8C);
  static const Color accentBlueSoft = Color(0xFFEAF1F7);

  static const Color neutralDark = Color(0xFF1F2937);
  static const Color neutralMedium = Color(0xFF374151);
  static const Color neutralSoft = Color(0xFF6B7280);

  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF1F4F8);

  static const Color taupe = Color(0xFF6B5B4D);
  static const Color taupeSoft = Color(0xFFF3EEE8);

  static const Color success = Color(0xFF1F8A4D);
  static const Color warning = Color(0xFFB7791F);
}

class Client {
  final String id;
  final String name;
  final String serviceType;
  final String contactEmail;
  final String contactPhone;
  final String notes;

  final int sessionDurationMinutes;
  final String sessionFrequency;
  final List<int> sessionWeekdays;
  final DateTime startDateTime;
  final DateTime endDateTime;

  final double hourlyRate;
  final bool hasVat;
  final PaymentType paymentType;

  Client({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.contactEmail,
    required this.contactPhone,
    required this.notes,
    required this.sessionDurationMinutes,
    required this.sessionFrequency,
    required this.sessionWeekdays,
    required this.startDateTime,
    required this.endDateTime,
    required this.hourlyRate,
    required this.hasVat,
    required this.paymentType,
  });
}

class SessionRecord {
  final String id;
  final String clientId;
  final DateTime dateTime;
  final DateTime scheduledFor;
  final int durationMinutes;
  final double amount;
  final bool isPaid;
  final String notes;

  SessionRecord({
    required this.id,
    required this.clientId,
    required this.dateTime,
    required this.scheduledFor,
    required this.durationMinutes,
    required this.amount,
    this.isPaid = false,
    this.notes = '',
  });
}

class WeeklyRegisterItem {
  final Client client;
  final DateTime scheduledDate;
  final String description;

  WeeklyRegisterItem({
    required this.client,
    required this.scheduledDate,
    required this.description,
  });
}

class ActivitySelectionScreen extends StatelessWidget {
  const ActivitySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final options = <_ActivityOption>[
      _ActivityOption(
        title: 'Educação',
        icon: Icons.school_outlined,
        type: ActivityType.education,
        color: AppColors.brandBlue,
        background: AppColors.brandBlueSoft,
      ),
      _ActivityOption(
        title: 'Fitness',
        icon: Icons.fitness_center_outlined,
        type: ActivityType.fitness,
        color: AppColors.accentBlue,
        background: AppColors.accentBlueSoft,
      ),
      _ActivityOption(
        title: 'Saúde',
        icon: Icons.favorite_border,
        type: ActivityType.health,
        color: AppColors.neutralMedium,
        background: AppColors.surfaceSoft,
      ),
      _ActivityOption(
        title: 'Outros Serviços',
        icon: Icons.work_outline,
        type: ActivityType.otherServices,
        color: AppColors.taupe,
        background: AppColors.taupeSoft,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AppHeader(),
              const SizedBox(height: 6),
              const Text(
                'Escolhe o tipo de atividade',
                style: TextStyle(
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  color: AppColors.neutralDark,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'A app adapta automaticamente as nomenclaturas à tua área profissional.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.neutralSoft,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HomeShell(activityType: option.type),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: option.background,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              option.icon,
                              size: 32,
                              color: option.color,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option.title,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: option.color,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: option.color,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final ActivityType activityType;

  const HomeShell({
    super.key,
    required this.activityType,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  final List<Client> _clients = [];
  final Map<String, List<SessionRecord>> _sessionsByClient = {};

  Future<void> _openAddClientScreen() async {
    final Client? newClient = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => AddClientScreen(activityType: widget.activityType),
      ),
    );

    if (newClient != null) {
      setState(() {
        _clients.add(newClient);
        _sessionsByClient[newClient.id] = [];
      });
    }
  }

  Future<void> _openClientDetail(Client client) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(
          client: client,
          activityType: widget.activityType,
          sessions: _sessionsByClient[client.id] ?? [],
        ),
      ),
    );
  }

  double _calculateSessionAmount(Client client, int durationMinutes) {
    double amount;

    if (widget.activityType == ActivityType.health &&
        client.paymentType == PaymentType.perSession) {
      amount = client.hourlyRate;
    } else {
      amount = (client.hourlyRate / 60) * durationMinutes;
    }

    if (client.hasVat) {
      amount = amount * 1.23;
    }

    return double.parse(amount.toStringAsFixed(2));
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime _endOfWeek(DateTime date) {
    final start = _startOfWeek(date);
    return DateTime(
      start.year,
      start.month,
      start.day + 6,
      23,
      59,
      59,
      999,
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _combineDateAndClientTime(DateTime day, Client client) {
    return DateTime(
      day.year,
      day.month,
      day.day,
      client.startDateTime.hour,
      client.startDateTime.minute,
    );
  }

  bool _isWithinClientPeriod(Client client, DateTime dateTime) {
    return !dateTime.isBefore(client.startDateTime) &&
        !dateTime.isAfter(client.endDateTime);
  }

  bool _hasRegisteredOccurrence(String clientId, DateTime scheduledDate) {
    final sessions = _sessionsByClient[clientId] ?? [];
    return sessions.any((session) => _isSameDate(session.scheduledFor, scheduledDate));
  }

  int _weeksBetween(DateTime from, DateTime to) {
    final fromWeek = _startOfWeek(from);
    final toWeek = _startOfWeek(to);
    return toWeek.difference(fromWeek).inDays ~/ 7;
  }

  List<DateTime> _plannedDatesForClientInCurrentWeek(Client client) {
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final weekEnd = _endOfWeek(now);
    final List<DateTime> planned = [];

    final effectiveWeekdays = client.sessionWeekdays.isEmpty
        ? <int>[client.startDateTime.weekday]
        : [...client.sessionWeekdays]..sort();

    final isOneOffProject = client.paymentType == PaymentType.oneOff;
    final frequency = client.sessionFrequency;

    if (isOneOffProject || frequency == 'Pontual') {
      if (!_isWithinClientPeriod(client, client.startDateTime)) {
        return [];
      }

      if (!client.startDateTime.isBefore(weekStart) &&
          !client.startDateTime.isAfter(weekEnd)) {
        planned.add(client.startDateTime);
      }
      return planned;
    }

    if (frequency == 'Semanal' ||
        frequency == '2x por semana' ||
        frequency == '3x por semana') {
      for (final weekday in effectiveWeekdays) {
        final day = weekStart.add(Duration(days: weekday - 1));
        final occurrence = _combineDateAndClientTime(day, client);

        if (_isWithinClientPeriod(client, occurrence) &&
            !occurrence.isBefore(weekStart) &&
            !occurrence.isAfter(weekEnd)) {
          planned.add(occurrence);
        }
      }
      return planned;
    }

    if (frequency == 'Quinzenal') {
      final weekday = effectiveWeekdays.first;
      final day = weekStart.add(Duration(days: weekday - 1));
      final occurrence = _combineDateAndClientTime(day, client);

      if (_isWithinClientPeriod(client, occurrence)) {
        final weeksDiff = _weeksBetween(client.startDateTime, occurrence);
        if (weeksDiff >= 0 && weeksDiff % 2 == 0) {
          planned.add(occurrence);
        }
      }
      return planned;
    }

    if (frequency == 'Mensal') {
      final occurrence = DateTime(
        now.year,
        now.month,
        client.startDateTime.day,
        client.startDateTime.hour,
        client.startDateTime.minute,
      );

      if (_isWithinClientPeriod(client, occurrence) &&
          !occurrence.isBefore(weekStart) &&
          !occurrence.isAfter(weekEnd)) {
        planned.add(occurrence);
      }
      return planned;
    }

    return planned;
  }

  List<WeeklyRegisterItem> get _weeklyRegisterItems {
    final List<WeeklyRegisterItem> items = [];

    for (final client in _clients) {
      final plannedDates = _plannedDatesForClientInCurrentWeek(client);

      for (final scheduledDate in plannedDates) {
        if (!_hasRegisteredOccurrence(client.id, scheduledDate)) {
          items.add(
            WeeklyRegisterItem(
              client: client,
              scheduledDate: scheduledDate,
              description: client.paymentType == PaymentType.oneOff
                  ? 'Projeto / Avulso'
                  : client.sessionFrequency,
            ),
          );
        }
      }
    }

    items.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return items;
  }

  void _registerWeeklyItem(WeeklyRegisterItem item) {
    final client = item.client;
    final amount = _calculateSessionAmount(client, client.sessionDurationMinutes);

    final session = SessionRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      clientId: client.id,
      dateTime: DateTime.now(),
      scheduledFor: item.scheduledDate,
      durationMinutes: client.sessionDurationMinutes,
      amount: amount,
    );

    setState(() {
      _sessionsByClient.putIfAbsent(client.id, () => []);
      _sessionsByClient[client.id]!.add(session);
    });

    final labels = getLabels(widget.activityType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${labels.sessionSingular} registada para ${client.name}',
        ),
        action: SnackBarAction(
          label: 'Anular',
          onPressed: () {
            _removeSession(client.id, session.id);
          },
        ),
      ),
    );
  }

  void _removeSession(String clientId, String sessionId) {
    setState(() {
      final sessions = _sessionsByClient[clientId];
      if (sessions == null) return;
      sessions.removeWhere((session) => session.id == sessionId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registo removido.'),
      ),
    );
  }

  void _markClientSessionsAsPaid(Client client) {
    final sessions = _sessionsByClient[client.id];
    if (sessions == null || sessions.isEmpty) return;

    bool updated = false;

    setState(() {
      for (var i = 0; i < sessions.length; i++) {
        final session = sessions[i];
        if (!session.isPaid) {
          sessions[i] = SessionRecord(
            id: session.id,
            clientId: session.clientId,
            dateTime: session.dateTime,
            scheduledFor: session.scheduledFor,
            durationMinutes: session.durationMinutes,
            amount: session.amount,
            isPaid: true,
            notes: session.notes,
          );
          updated = true;
        }
      }
    });

    if (updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pagamentos de ${client.name} marcados como pagos.'),
        ),
      );
    }
  }

  int get totalSessionsCount {
    int total = 0;
    for (final sessions in _sessionsByClient.values) {
      total += sessions.length;
    }
    return total;
  }

  double get totalPendingAmount {
    double total = 0;
    for (final sessions in _sessionsByClient.values) {
      for (final session in sessions) {
        if (!session.isPaid) {
          total += session.amount;
        }
      }
    }
    return double.parse(total.toStringAsFixed(2));
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return DashboardTab(
          activityType: widget.activityType,
          clientCount: _clients.length,
          sessionCount: totalSessionsCount,
          pendingAmount: totalPendingAmount,
          onAddClient: _openAddClientScreen,
          onOpenQuickRegister: () {
            setState(() {
              _currentIndex = 2;
            });
          },
        );
      case 1:
        return ClientsTab(
          activityType: widget.activityType,
          clients: _clients,
          onAddClient: _openAddClientScreen,
          onOpenClient: _openClientDetail,
        );
      case 2:
        return QuickRegisterTab(
          activityType: widget.activityType,
          items: _weeklyRegisterItems,
          onRegisterItem: _registerWeeklyItem,
        );
      case 3:
        return SessionsTab(
          activityType: widget.activityType,
          clients: _clients,
          sessionsByClient: _sessionsByClient,
          onDeleteSession: _removeSession,
        );
      case 4:
        return PaymentsTab(
          activityType: widget.activityType,
          clients: _clients,
          sessionsByClient: _sessionsByClient,
          onOpenClient: _openClientDetail,
          onMarkClientAsPaid: _markClientSessionsAsPaid,
        );
      default:
        return DashboardTab(
          activityType: widget.activityType,
          clientCount: _clients.length,
          sessionCount: totalSessionsCount,
          pendingAmount: totalPendingAmount,
          onAddClient: _openAddClientScreen,
          onOpenQuickRegister: () {
            setState(() {
              _currentIndex = 2;
            });
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.brandBlue,
        unselectedItemColor: AppColors.neutralSoft,
        backgroundColor: AppColors.surfaceWhite,
        elevation: 8,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            label: _bottomNavClientLabel(widget.activityType),
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Registar',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_note_outlined),
            label: _bottomNavSessionLabel(widget.activityType),
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'Pagamentos',
          ),
        ],
      ),
    );
  }

  static String _bottomNavClientLabel(ActivityType type) {
    switch (type) {
      case ActivityType.education:
        return 'Alunos';
      case ActivityType.fitness:
        return 'Alunos';
      case ActivityType.health:
        return 'Utentes';
      case ActivityType.otherServices:
        return 'Clientes';
    }
  }

  static String _bottomNavSessionLabel(ActivityType type) {
    switch (type) {
      case ActivityType.education:
        return 'Aulas';
      case ActivityType.fitness:
        return 'Treinos';
      case ActivityType.health:
        return 'Consultas';
      case ActivityType.otherServices:
        return 'Sessões';
    }
  }
}

class DashboardTab extends StatelessWidget {
  final ActivityType activityType;
  final int clientCount;
  final int sessionCount;
  final double pendingAmount;
  final VoidCallback onAddClient;
  final VoidCallback onOpenQuickRegister;

  const DashboardTab({
    super.key,
    required this.activityType,
    required this.clientCount,
    required this.sessionCount,
    required this.pendingAmount,
    required this.onAddClient,
    required this.onOpenQuickRegister,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: ListView(
          children: [
            const _AppHeader(),
            const SizedBox(height: 6),
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.neutralDark,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              labels.areaName,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.neutralSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Ações rápidas'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Novo ${labels.clientSingular}',
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
                    label: 'Registar ${labels.sessionSingular}',
                    iconColor: AppColors.accentBlue,
                    textColor: AppColors.accentBlue,
                    background: AppColors.accentBlueSoft,
                    onTap: onOpenQuickRegister,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.calendar_month_outlined,
                    label: 'Horário',
                    iconColor: AppColors.neutralMedium,
                    textColor: AppColors.neutralMedium,
                    background: AppColors.surfaceSoft,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            SectionTitle(title: 'Próximas ${labels.sessionPlural}'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Na aba “Registar” aparecem apenas as ${labels.sessionPlural.toLowerCase()} previstas para a semana atual, incluindo sessões avulso e projetos.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.neutralSoft,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const SectionTitle(title: 'Estatísticas'),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: labels.clientPlural,
                    value: '$clientCount',
                    valueColor: AppColors.brandBlue,
                    background: AppColors.brandBlueSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: 'Cobrança pendente',
                    value: '${pendingAmount.toStringAsFixed(2)}€',
                    valueColor: AppColors.accentBlue,
                    background: AppColors.accentBlueSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            const SectionTitle(title: 'Resumo'),
            const SizedBox(height: 14),
            _InfoTile(
              icon: Icons.group_outlined,
              title: labels.clientPlural,
              subtitle: '$clientCount registados',
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.event_available_outlined,
              title: labels.sessionPlural,
              subtitle: '$sessionCount registadas',
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.payments_outlined,
              title: 'Pagamentos',
              subtitle: '${pendingAmount.toStringAsFixed(2)}€ por regularizar',
            ),
          ],
        ),
      ),
    );
  }
}

class ClientsTab extends StatelessWidget {
  final ActivityType activityType;
  final List<Client> clients;
  final VoidCallback onAddClient;
  final ValueChanged<Client> onOpenClient;

  const ClientsTab({
    super.key,
    required this.activityType,
    required this.clients,
    required this.onAddClient,
    required this.onOpenClient,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);

    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AppHeader(),
                const SizedBox(height: 6),
                Text(
                  labels.clientPlural,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.neutralDark,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${clients.length} registados',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.neutralSoft,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: clients.isEmpty
                      ? _EmptyClientsState(
                          activityType: activityType,
                          onAddClient: onAddClient,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: clients.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            return ClientCard(
                              client: client,
                              activityType: activityType,
                              onTap: () => onOpenClient(client),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (clients.isNotEmpty)
            Positioned(
              right: 24,
              bottom: 24,
              child: FloatingActionButton.extended(
                onPressed: onAddClient,
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: Text('Novo ${labels.clientSingular}'),
              ),
            ),
        ],
      ),
    );
  }
}

class QuickRegisterTab extends StatelessWidget {
  final ActivityType activityType;
  final List<WeeklyRegisterItem> items;
  final ValueChanged<WeeklyRegisterItem> onRegisterItem;

  const QuickRegisterTab({
    super.key,
    required this.activityType,
    required this.items,
    required this.onRegisterItem,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AppHeader(),
            const SizedBox(height: 6),
            Text(
              'Registar ${labels.sessionSingular}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.neutralDark,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Semana de ${_formatShortDate(weekStart)} a ${_formatShortDate(weekEnd)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.neutralSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: items.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Não há ${labels.sessionPlural.toLowerCase()} pendentes para esta semana.',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.neutralSoft,
                          height: 1.4,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final client = item.client;
                        final subtitle = client.serviceType.trim().isNotEmpty
                            ? client.serviceType
                            : labels.clientSingular;

                        return InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () => onRegisterItem(item),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceWhite,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentBlueSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    _registerIcon(activityType),
                                    color: AppColors.accentBlue,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.neutralDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.neutralSoft,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${_weekdayName(item.scheduledDate.weekday)} • ${_formatShortDate(item.scheduledDate)} • ${item.description}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.neutralMedium,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.brandBlue,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _registerIcon(ActivityType type) {
    switch (type) {
      case ActivityType.education:
        return Icons.menu_book_outlined;
      case ActivityType.fitness:
        return Icons.fitness_center_outlined;
      case ActivityType.health:
        return Icons.medical_services_outlined;
      case ActivityType.otherServices:
        return Icons.event_note_outlined;
    }
  }

  static String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  static String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return '2.ª';
      case DateTime.tuesday:
        return '3.ª';
      case DateTime.wednesday:
        return '4.ª';
      case DateTime.thursday:
        return '5.ª';
      case DateTime.friday:
        return '6.ª';
      case DateTime.saturday:
        return 'Sáb';
      case DateTime.sunday:
        return 'Dom';
      default:
        return '';
    }
  }
}

class AddClientScreen extends StatefulWidget {
  final ActivityType activityType;

  const AddClientScreen({
    super.key,
    required this.activityType,
  });

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  int _sessionDurationMinutes = 60;
  String _sessionFrequency = 'Semanal';
  late DateTime _startDateTime;
  late DateTime _endDateTime;

  bool _hasVat = false;
  PaymentType _paymentType = PaymentType.perSession;
  List<int> _selectedWeekdays = [];

  ActivityLabels get labels => getLabels(widget.activityType);

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      0,
    );
    _endDateTime = _startDateTime.add(
      Duration(minutes: _sessionDurationMinutes),
    );
    _selectedWeekdays = [_startDateTime.weekday];
  }

  int _requiredWeekdayCount() {
    switch (_sessionFrequency) {
      case 'Semanal':
        return 1;
      case '2x por semana':
        return 2;
      case '3x por semana':
        return 3;
      case 'Quinzenal':
        return 1;
      default:
        return 0;
    }
  }

  bool get _showsWeekdaySelector => _requiredWeekdayCount() > 0;

  void _syncSelectedWeekdaysWithFrequency() {
    final required = _requiredWeekdayCount();

    if (required == 0) {
      _selectedWeekdays = [];
      return;
    }

    if (_selectedWeekdays.isEmpty) {
      _selectedWeekdays = [_startDateTime.weekday];
    }

    while (_selectedWeekdays.length > required) {
      _selectedWeekdays.removeLast();
    }

    while (_selectedWeekdays.length < required) {
      for (int i = 1; i <= 7; i++) {
        if (!_selectedWeekdays.contains(i)) {
          _selectedWeekdays.add(i);
          if (_selectedWeekdays.length == required) break;
        }
      }
    }

    _selectedWeekdays.sort();
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Indica o nome.';
    }

    final nameRegex = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ0-9\s.\-]+$');
    if (!nameRegex.hasMatch(text)) {
      return 'O nome contém caracteres inválidos.';
    }

    return null;
  }

  String? _validateEmail(String? value, {bool requiredField = false}) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return requiredField ? 'Indica um email.' : null;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'Indica um email válido.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final phoneRegex = RegExp(r'^\d+$');
    if (!phoneRegex.hasMatch(text)) {
      return 'O telefone deve conter apenas números.';
    }

    return null;
  }

  String? _validateRate(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Indica o valor.';
    }

    final normalized = text.replaceAll(',', '.');
    final number = double.tryParse(normalized);

    if (number == null || number <= 0) {
      return 'Indica um valor válido.';
    }

    return null;
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final currentValue = isStart ? _startDateTime : _endDateTime;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: currentValue,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentValue),
      initialEntryMode: TimePickerEntryMode.inputOnly,
    );

    if (pickedTime == null) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _startDateTime = newDateTime;
        _endDateTime = _startDateTime.add(
          Duration(minutes: _sessionDurationMinutes),
        );

        if (_showsWeekdaySelector && _selectedWeekdays.isEmpty) {
          _selectedWeekdays = [_startDateTime.weekday];
          _syncSelectedWeekdaysWithFrequency();
        }
      } else {
        if (newDateTime.isAfter(_startDateTime)) {
          _endDateTime = newDateTime;
        } else {
          _endDateTime = _startDateTime.add(
            Duration(minutes: _sessionDurationMinutes),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'A data/hora de fim tem de ser posterior ao início.',
              ),
            ),
          );
        }
      }
    });
  }

  void _updateSessionDuration(int minutes) {
    setState(() {
      _sessionDurationMinutes = minutes;
      _endDateTime = _startDateTime.add(
        Duration(minutes: _sessionDurationMinutes),
      );
    });
  }

  void _toggleWeekday(int weekday) {
    final required = _requiredWeekdayCount();

    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(weekday);
        }
      } else {
        if (_selectedWeekdays.length < required) {
          _selectedWeekdays.add(weekday);
        }
      }
      _selectedWeekdays.sort();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serviceTypeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final requiredWeekdays = _requiredWeekdayCount();
    if (requiredWeekdays > 0 && _selectedWeekdays.length != requiredWeekdays) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Seleciona exatamente $requiredWeekdays dia(s) para esta frequência.',
          ),
        ),
      );
      return;
    }

    final client = Client(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      serviceType: _serviceTypeController.text.trim(),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      notes: _notesController.text.trim(),
      sessionDurationMinutes: _sessionDurationMinutes,
      sessionFrequency: _sessionFrequency,
      sessionWeekdays: [..._selectedWeekdays]..sort(),
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      hourlyRate: double.parse(
        _hourlyRateController.text.trim().replaceAll(',', '.'),
      ),
      hasVat: _hasVat,
      paymentType: _paymentType,
    );

    Navigator.of(context).pop(client);
  }

  @override
  Widget build(BuildContext context) {
    final singularLower = labels.clientSingular.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: AppColors.surface,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(fontSize: 16),
          ),
        ),
        leadingWidth: 100,
        title: Text(
          'Novo ${labels.clientSingular}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.neutralDark,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormSectionTitle(title: 'Informações do $singularLower'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      _SchedifyTextField(
                        controller: _nameController,
                        label: 'Nome',
                        validator: _validateName,
                      ),
                      const SizedBox(height: 14),
                      _SchedifyTextField(
                        controller: _serviceTypeController,
                        label: labels.serviceTypeLabel,
                      ),
                      const SizedBox(height: 14),
                      _SchedifyTextField(
                        controller: _emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                            _validateEmail(value, requiredField: true),
                      ),
                      const SizedBox(height: 14),
                      _SchedifyTextField(
                        controller: _phoneController,
                        label: 'Telefone',
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 14),
                      _SchedifyTextField(
                        controller: _notesController,
                        label: 'Notas',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _FormSectionTitle(
                  title:
                      'Configuração da ${labels.sessionSingular.toLowerCase()}',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _sessionDurationMinutes,
                        decoration: _inputDecoration(labels.durationLabel),
                        items: const [
                          DropdownMenuItem(
                            value: 30,
                            child: Text('30 minutos'),
                          ),
                          DropdownMenuItem(
                            value: 45,
                            child: Text('45 minutos'),
                          ),
                          DropdownMenuItem(
                            value: 60,
                            child: Text('60 minutos'),
                          ),
                          DropdownMenuItem(
                            value: 90,
                            child: Text('90 minutos'),
                          ),
                          DropdownMenuItem(
                            value: 120,
                            child: Text('120 minutos'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          _updateSessionDuration(value);
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _sessionFrequency,
                        decoration: _inputDecoration(labels.frequencyLabel),
                        items: const [
                          DropdownMenuItem(
                            value: 'Semanal',
                            child: Text('Semanal'),
                          ),
                          DropdownMenuItem(
                            value: '2x por semana',
                            child: Text('2x por semana'),
                          ),
                          DropdownMenuItem(
                            value: '3x por semana',
                            child: Text('3x por semana'),
                          ),
                          DropdownMenuItem(
                            value: 'Quinzenal',
                            child: Text('Quinzenal'),
                          ),
                          DropdownMenuItem(
                            value: 'Mensal',
                            child: Text('Mensal'),
                          ),
                          DropdownMenuItem(
                            value: 'Pontual',
                            child: Text('Pontual'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _sessionFrequency = value;
                            _syncSelectedWeekdaysWithFrequency();
                          });
                        },
                      ),
                      if (_showsWeekdaySelector) ...[
                        const SizedBox(height: 14),
                        _WeekdaySelector(
                          selectedWeekdays: _selectedWeekdays,
                          maxSelection: _requiredWeekdayCount(),
                          onToggle: _toggleWeekday,
                        ),
                      ],
                      const SizedBox(height: 14),
                      _DateTimePickerField(
                        label: 'Data e hora de início',
                        value: _startDateTime,
                        onTap: () => _pickDateTime(isStart: true),
                      ),
                      const SizedBox(height: 14),
                      _DateTimePickerField(
                        label: 'Data e hora de fim',
                        value: _endDateTime,
                        onTap: () => _pickDateTime(isStart: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _FormSectionTitle(title: 'Configuração do pagamento'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      _SchedifyTextField(
                        controller: _hourlyRateController,
                        label: labels.rateLabel,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _validateRate,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<PaymentType>(
                        initialValue: _paymentType,
                        decoration: _inputDecoration('Frequência do pagamento'),
                        items: [
                          DropdownMenuItem(
                            value: PaymentType.perSession,
                            child: Text(
                              'Por ${labels.sessionSingular.toLowerCase()}',
                            ),
                          ),
                          const DropdownMenuItem(
                            value: PaymentType.monthly,
                            child: Text('Mensal'),
                          ),
                          const DropdownMenuItem(
                            value: PaymentType.oneOff,
                            child: Text('Avulso / Projeto'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _paymentType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _hasVat,
                        onChanged: (value) {
                          setState(() {
                            _hasVat = value;
                          });
                        },
                        title: const Text('Com IVA'),
                        activeThumbColor: AppColors.brandBlue,
                        activeTrackColor: AppColors.brandBlueSoft,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlueSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Na aba “Registar” vão aparecer apenas as ${labels.sessionPlural.toLowerCase()} da semana atual que ainda não tenham sido validadas.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutralMedium,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClientDetailScreen extends StatelessWidget {
  final Client client;
  final ActivityType activityType;
  final List<SessionRecord> sessions;

  const ClientDetailScreen({
    super.key,
    required this.client,
    required this.activityType,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);

    final sortedSessions = [...sessions]
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

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
          style: const TextStyle(
            color: AppColors.neutralDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: ListView(
            children: [
              Text(
                labels.clientSingular,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.neutralSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle(title: 'Informações'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(label: 'Nome', value: _orDash(client.name)),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: labels.serviceTypeLabel,
                      value: _orDash(client.serviceType),
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Email',
                      value: _orDash(client.contactEmail),
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Telefone',
                      value: _orDash(client.contactPhone),
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(label: 'Notas', value: _orDash(client.notes)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(
                title: 'Configuração da ${labels.sessionSingular.toLowerCase()}',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(
                      label: 'Duração',
                      value: '${client.sessionDurationMinutes} min',
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Frequência',
                      value: client.sessionFrequency,
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Dias',
                      value: client.sessionWeekdays.isEmpty
                          ? '—'
                          : client.sessionWeekdays
                              .map(_weekdayFullName)
                              .join(', '),
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Início',
                      value: _formatDateTime(client.startDateTime),
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Fim',
                      value: _formatDateTime(client.endDateTime),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle(title: 'Configuração do pagamento'),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailLine(
                      label: 'Valor',
                      value: '${client.hourlyRate.toStringAsFixed(2)}€',
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'IVA',
                      value: client.hasVat ? 'Sim' : 'Não',
                    ),
                    const SizedBox(height: 10),
                    _DetailLine(
                      label: 'Pagamento',
                      value: _paymentTypeText(client.paymentType, labels),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionTitle(title: labels.sessionPlural),
              const SizedBox(height: 14),
              if (sortedSessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Ainda não há ${labels.sessionPlural.toLowerCase()} registadas.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.neutralSoft,
                    ),
                  ),
                )
              else
                ...sortedSessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ClientSessionMiniCard(
                      session: session,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _orDash(String value) {
    return value.trim().isEmpty ? '—' : value;
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  static String _paymentTypeText(
    PaymentType type,
    ActivityLabels labels,
  ) {
    switch (type) {
      case PaymentType.perSession:
        return 'Por ${labels.sessionSingular.toLowerCase()}';
      case PaymentType.monthly:
        return 'Mensal';
      case PaymentType.oneOff:
        return 'Avulso / Projeto';
    }
  }

  static String _weekdayFullName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Segunda';
      case DateTime.tuesday:
        return 'Terça';
      case DateTime.wednesday:
        return 'Quarta';
      case DateTime.thursday:
        return 'Quinta';
      case DateTime.friday:
        return 'Sexta';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return '';
    }
  }
}

class SessionsTab extends StatelessWidget {
  final ActivityType activityType;
  final List<Client> clients;
  final Map<String, List<SessionRecord>> sessionsByClient;
  final void Function(String clientId, String sessionId) onDeleteSession;

  const SessionsTab({
    super.key,
    required this.activityType,
    required this.clients,
    required this.sessionsByClient,
    required this.onDeleteSession,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);

    final List<_SessionListItem> allSessions = [];

    for (final client in clients) {
      final sessions = sessionsByClient[client.id] ?? [];
      for (final session in sessions) {
        allSessions.add(
          _SessionListItem(
            client: client,
            session: session,
          ),
        );
      }
    }

    allSessions.sort(
      (a, b) => b.session.dateTime.compareTo(a.session.dateTime),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AppHeader(),
            const SizedBox(height: 6),
            Text(
              labels.sessionPlural,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.neutralDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${allSessions.length} registadas',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.neutralSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: allSessions.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Ainda não há ${labels.sessionPlural.toLowerCase()} registadas.',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.neutralSoft,
                          height: 1.4,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: allSessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = allSessions[index];
                        return SessionCard(
                          activityType: activityType,
                          client: item.client,
                          session: item.session,
                          onDelete: () => onDeleteSession(
                            item.client.id,
                            item.session.id,
                          ),
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

class PaymentsTab extends StatelessWidget {
  final ActivityType activityType;
  final List<Client> clients;
  final Map<String, List<SessionRecord>> sessionsByClient;
  final ValueChanged<Client> onOpenClient;
  final ValueChanged<Client> onMarkClientAsPaid;

  const PaymentsTab({
    super.key,
    required this.activityType,
    required this.clients,
    required this.sessionsByClient,
    required this.onOpenClient,
    required this.onMarkClientAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);

    final List<_PaymentSummaryItem> pendingClients = [];

    for (final client in clients) {
      final sessions = sessionsByClient[client.id] ?? [];
      final pendingSessions =
          sessions.where((session) => !session.isPaid).toList();

      if (pendingSessions.isNotEmpty) {
        final totalPending = pendingSessions.fold<double>(
          0,
          (sum, session) => sum + session.amount,
        );

        pendingClients.add(
          _PaymentSummaryItem(
            client: client,
            pendingCount: pendingSessions.length,
            pendingAmount: double.parse(totalPending.toStringAsFixed(2)),
          ),
        );
      }
    }

    pendingClients.sort((a, b) => b.pendingAmount.compareTo(a.pendingAmount));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _AppHeader(),
            const SizedBox(height: 6),
            const Text(
              'Pagamentos',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.neutralDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              pendingClients.isEmpty
                  ? 'Sem pagamentos pendentes'
                  : '${pendingClients.length} ${labels.clientPlural.toLowerCase()} com pagamentos pendentes',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.neutralSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: pendingClients.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Text(
                        'Quando existirem sessões pendentes, vão aparecer aqui os resumos de cobrança.',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.neutralSoft,
                          height: 1.4,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: pendingClients.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = pendingClients[index];
                        return PaymentSummaryCard(
                          activityType: activityType,
                          client: item.client,
                          pendingCount: item.pendingCount,
                          pendingAmount: item.pendingAmount,
                          onOpenClient: () => onOpenClient(item.client),
                          onMarkAsPaid: () => onMarkClientAsPaid(item.client),
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

class _SessionListItem {
  final Client client;
  final SessionRecord session;

  _SessionListItem({
    required this.client,
    required this.session,
  });
}

class _PaymentSummaryItem {
  final Client client;
  final int pendingCount;
  final double pendingAmount;

  _PaymentSummaryItem({
    required this.client,
    required this.pendingCount,
    required this.pendingAmount,
  });
}

class SessionCard extends StatelessWidget {
  final ActivityType activityType;
  final Client client;
  final SessionRecord session;
  final VoidCallback onDelete;

  const SessionCard({
    super.key,
    required this.activityType,
    required this.client,
    required this.session,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentBlueSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _sessionIcon(activityType),
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.neutralDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  client.serviceType.trim().isNotEmpty
                      ? client.serviceType
                      : labels.clientSingular,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutralSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Registo: ${_formatDateTime(session.dateTime)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutralMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prevista: ${_formatDateTime(session.scheduledFor)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.neutralMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session.durationMinutes} min • ${session.amount.toStringAsFixed(2)}€',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutralSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: session.isPaid
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.isPaid ? 'Pago' : 'Pendente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: session.isPaid ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.neutralSoft,
                tooltip: 'Apagar registo',
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _sessionIcon(ActivityType type) {
    switch (type) {
      case ActivityType.education:
        return Icons.menu_book_outlined;
      case ActivityType.fitness:
        return Icons.fitness_center_outlined;
      case ActivityType.health:
        return Icons.medical_services_outlined;
      case ActivityType.otherServices:
        return Icons.event_note_outlined;
    }
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }
}

class PaymentSummaryCard extends StatelessWidget {
  final ActivityType activityType;
  final Client client;
  final int pendingCount;
  final double pendingAmount;
  final VoidCallback onOpenClient;
  final VoidCallback onMarkAsPaid;

  const PaymentSummaryCard({
    super.key,
    required this.activityType,
    required this.client,
    required this.pendingCount,
    required this.pendingAmount,
    required this.onOpenClient,
    required this.onMarkAsPaid,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.brandBlueSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.brandBlue,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: onOpenClient,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutralDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.serviceType.trim().isNotEmpty
                            ? client.serviceType
                            : labels.clientSingular,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.neutralSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${pendingAmount.toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pendingCount pendente(s)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.neutralSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenClient,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver ficha'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onMarkAsPaid,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Marcar como pago'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClientSessionMiniCard extends StatelessWidget {
  final SessionRecord session;

  const _ClientSessionMiniCard({
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final day = session.dateTime.day.toString().padLeft(2, '0');
    final month = session.dateTime.month.toString().padLeft(2, '0');
    final year = session.dateTime.year.toString();
    final hour = session.dateTime.hour.toString().padLeft(2, '0');
    final minute = session.dateTime.minute.toString().padLeft(2, '0');

    final scheduledDay = session.scheduledFor.day.toString().padLeft(2, '0');
    final scheduledMonth = session.scheduledFor.month.toString().padLeft(2, '0');
    final scheduledYear = session.scheduledFor.year.toString();
    final scheduledHour = session.scheduledFor.hour.toString().padLeft(2, '0');
    final scheduledMinute = session.scheduledFor.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Registo: $day/$month/$year • $hour:$minute\nPrevista: $scheduledDay/$scheduledMonth/$scheduledYear • $scheduledHour:$scheduledMinute\n${session.durationMinutes} min • ${session.amount.toStringAsFixed(2)}€',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.neutralSoft,
                height: 1.4,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: session.isPaid
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.isPaid ? 'Pago' : 'Pendente',
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

class ClientCard extends StatelessWidget {
  final Client client;
  final ActivityType activityType;
  final VoidCallback onTap;

  const ClientCard({
    super.key,
    required this.client,
    required this.activityType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = client.serviceType.trim().isNotEmpty
        ? client.serviceType
        : client.contactEmail;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brandBlueSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.person_outline,
                color: AppColors.brandBlue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.neutralDark,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.neutralSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.neutralSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyClientsState extends StatelessWidget {
  final ActivityType activityType;
  final VoidCallback onAddClient;

  const _EmptyClientsState({
    required this.activityType,
    required this.onAddClient,
  });

  @override
  Widget build(BuildContext context) {
    final labels = getLabels(activityType);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandBlueSoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.group_outlined,
                size: 34,
                color: AppColors.brandBlue,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Ainda não há ${labels.clientPlural.toLowerCase()} registados',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.neutralDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Começa por adicionar o primeiro ${labels.clientSingular.toLowerCase()} com a respetiva configuração base.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.neutralSoft,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddClient,
              icon: const Icon(Icons.add),
              label: Text('Novo ${labels.clientSingular}'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  final List<int> selectedWeekdays;
  final int maxSelection;
  final ValueChanged<int> onToggle;

  const _WeekdaySelector({
    required this.selectedWeekdays,
    required this.maxSelection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = {
      1: 'Seg',
      2: 'Ter',
      3: 'Qua',
      4: 'Qui',
      5: 'Sex',
      6: 'Sáb',
      7: 'Dom',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dias da semana ($maxSelection)',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.neutralSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weekdayLabels.entries.map((entry) {
            final selected = selectedWeekdays.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onToggle(entry.key),
              selectedColor: AppColors.brandBlueSoft,
              checkmarkColor: AppColors.brandBlue,
              labelStyle: TextStyle(
                color: selected ? AppColors.brandBlue : AppColors.neutralMedium,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
              backgroundColor: AppColors.surface,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SchedifyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _SchedifyTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.neutralDark,
      ),
      decoration: _inputDecoration(label),
    );
  }
}

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
      color: AppColors.neutralSoft,
    ),
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.brandBlue),
    ),
  );
}

class _DateTimePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _DateTimePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final text = '$day/$month/$year • $hour:$minute';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: _inputDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.neutralDark,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.neutralSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSectionTitle extends StatelessWidget {
  final String title;

  const _FormSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.neutralSoft,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralMedium,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutralSoft,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 8,
      ),
      child: SizedBox(
        height: 100,
        child: Image.asset(
          'assets/images/schedify_logo_horizontal.png',
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.neutralDark,
        height: 1.15,
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color background;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: iconColor),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final Color background;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutralSoft,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandBlue, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.neutralDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.neutralSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityOption {
  final String title;
  final IconData icon;
  final ActivityType type;
  final Color color;
  final Color background;

  _ActivityOption({
    required this.title,
    required this.icon,
    required this.type,
    required this.color,
    required this.background,
  });
}