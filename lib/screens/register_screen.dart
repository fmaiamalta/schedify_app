import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../theme.dart';

/// Ecrã completo (não uma folha modal) para registar sessões de hoje ou de
/// até 1 semana atrás. Usar um ecrã inteiro em vez de um bottom sheet evita
/// problemas de altura em janelas grandes (desktop/web).
///
/// A lista é sempre recalculada a partir de [occurrencesProvider] sempre que
/// [sessionsTick] muda — nunca guarda uma cópia local — para que "Anular" no
/// snackbar de registo se reflita aqui de imediato, sem ser preciso sair e
/// voltar a entrar no ecrã.
class RegisterScreen extends StatefulWidget {
  final AppStrings strings;
  final ValueListenable<int> sessionsTick;
  final List<PlannedOccurrence> Function() occurrencesProvider;
  final ValueChanged<PlannedOccurrence> onRegisterOccurrence;

  const RegisterScreen({
    super.key,
    required this.strings,
    required this.sessionsTick,
    required this.occurrencesProvider,
    required this.onRegisterOccurrence,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  @override
  void initState() {
    super.initState();
    widget.sessionsTick.addListener(_onSessionsChanged);
  }

  @override
  void dispose() {
    widget.sessionsTick.removeListener(_onSessionsChanged);
    super.dispose();
  }

  void _onSessionsChanged() {
    if (mounted) setState(() {});
  }

  static String _formatDateTime(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final pending = widget.occurrencesProvider();
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        title: Text(s.registerButton, style: const TextStyle(color: AppColors.neutralDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.registerableSubtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.neutralSoft),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: pending.isEmpty
                    ? Center(
                        child: Text(s.nothingToRegister, style: const TextStyle(color: AppColors.neutralSoft)),
                      )
                    : ListView.separated(
                        itemCount: pending.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final occurrence = pending[index];
                          // A lista mistura ocorrências de todas as atividades em uso, por
                          // isso o nome da sessão vem sempre do tipo de atividade do próprio
                          // cliente, não da área de trabalho atual (ver comentário em
                          // registerableSubtitle).
                          final sessionNoun = getLabels(occurrence.client.activityType, s.language).sessionSingular;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(18)),
                            child: Row(
                              children: [
                                const Icon(Icons.watch_later_outlined, color: AppColors.warning),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(occurrence.client.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(
                                        '$sessionNoun • ${s.weekdayShort(occurrence.scheduledFor.weekday)} • ${_formatDateTime(occurrence.scheduledFor)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.neutralSoft),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () => widget.onRegisterOccurrence(occurrence),
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.brandGreen, foregroundColor: Colors.white),
                                  child: Text(s.registerButton),
                                ),
                              ],
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
