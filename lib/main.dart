import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'home_shell.dart';
import 'i18n/app_strings.dart';
import 'models.dart';
import 'services/storage_service.dart';
import 'theme.dart';
import 'widgets/shared_widgets.dart';

void main() async {
  // O layout de todos os ecrãs foi desenhado só para retrato (cartões e
  // barra de navegação inferior de largura fixa); em paisagem alguns ecrãs
  // (ex.: Alunos, Disciplinas) sofrem overflow vertical porque o cabeçalho e
  // os títulos fixos não cabem na altura menor. Bloquear a orientação evita
  // esta classe de problema em vez de reescrever cada ecrã para paisagem.
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const SchedifyApp());
}

class SchedifyApp extends StatelessWidget {
  const SchedifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: currentAppLanguage,
      builder: (context, language, _) {
        return MaterialApp(
          title: 'Schedify',
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF7F8FA),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B2A7A)),
            useMaterial3: true,
          ),
          locale: localeFor(language),
          supportedLocales: const [Locale('pt'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const StartupGate(),
        );
      },
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
    // Efeito à parte (não dentro de build()): atualizar o ValueNotifier
    // global durante um build causaria um rebuild reentrante do próprio
    // MaterialApp (que o escuta) a meio de outro build.
    _future.then((state) {
      currentAppLanguage.value = state?.language ?? AppLanguage.pt;
    });
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
          initialProviderName: state.providerName,
          initialClients: state.clients,
          initialSessions: state.sessionsByClient,
        );
      },
    );
  }
}

class ActivitySelectionScreen extends StatefulWidget {
  final AppLanguage initialLanguage;

  const ActivitySelectionScreen({super.key, this.initialLanguage = AppLanguage.pt});

  @override
  State<ActivitySelectionScreen> createState() => _ActivitySelectionScreenState();
}

class _ActivitySelectionScreenState extends State<ActivitySelectionScreen> {
  final _nameController = TextEditingController();
  bool _showNameError = false;

  AppStrings get s => AppStrings(widget.initialLanguage);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectActivity(ActivityType type) {
    final providerName = _nameController.text.trim();
    if (providerName.isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    // pushReplacement (não push): a escolha do tipo de atividade é uma
    // decisão de arranque única, não um ecrã para onde se deva poder
    // voltar — caso contrário, o botão de recuar (Android) volta a
    // mostrar o onboarding a partir de qualquer separador principal.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeShell(
          initialActivityType: type,
          initialLanguage: widget.initialLanguage,
          initialProviderName: providerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                s.providerNameTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutralSoft, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                s.providerNameSubtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.neutralSoft),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: _showNameError ? Border.all(color: Colors.redAccent) : null,
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(border: InputBorder.none, hintText: s.providerNameHint),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) {
                    if (_showNameError) setState(() => _showNameError = false);
                  },
                ),
              ),
              if (_showNameError) ...[
                const SizedBox(height: 6),
                Text(s.providerNameRequiredError, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
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
                    final title = getLabels(type, widget.initialLanguage).areaName;
                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _selectActivity(type),
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
