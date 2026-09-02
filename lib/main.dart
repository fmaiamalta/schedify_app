import 'package:flutter/material.dart';
import 'home_shell.dart';
import 'i18n/app_strings.dart';
import 'models.dart';
import 'services/storage_service.dart';
import 'theme.dart';
import 'widgets/shared_widgets.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B2A7A)),
        useMaterial3: true,
      ),
      home: const StartupGate(),
    );
  }
}

/// Carrega os dados guardados no dispositivo (se existirem) antes de decidir
/// se mostra a seleção de tipo de atividade (primeira utilização) ou entra
/// diretamente na app com tudo restaurado.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  late Future<PersistedState?> _future;

  @override
  void initState() {
    super.initState();
    _future = StorageService().load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PersistedState?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final state = snapshot.data;
        if (state == null || state.clients.isEmpty) {
          // Primeira utilização (ou sem dados ainda): pede o tipo de atividade.
          return ActivitySelectionScreen(initialLanguage: state?.language ?? AppLanguage.pt);
        }

        return HomeShell(
          initialActivityType: state.activityType,
          initialLanguage: state.language,
          initialClients: state.clients,
          initialSessions: state.sessionsByClient,
        );
      },
    );
  }
}

class ActivitySelectionScreen extends StatelessWidget {
  final AppLanguage initialLanguage;

  const ActivitySelectionScreen({super.key, this.initialLanguage = AppLanguage.pt});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(initialLanguage);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(),
              const SizedBox(height: 6),
              Text(
                s.chooseActivityTitle,
                style: const TextStyle(fontSize: 31, fontWeight: FontWeight.w800, color: AppColors.neutralDark, height: 1.1),
              ),
              const SizedBox(height: 10),
              Text(
                s.chooseActivitySubtitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.neutralSoft, height: 1.35),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: ActivityType.values.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final type = ActivityType.values[index];
                    final color = colorForActivityType(type);
                    final title = getLabels(type, initialLanguage).areaName;
                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HomeShell(initialActivityType: type, initialLanguage: initialLanguage),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(22)),
                        child: Row(
                          children: [
                            Icon(iconForActivityType(type), size: 32, color: color),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: color),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
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
