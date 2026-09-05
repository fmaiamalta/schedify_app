import 'package:url_launcher/url_launcher.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import 'schedule_logic.dart';

String _formatDayMonth(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month';
}

/// Constrói a mensagem de relatório com o template exato pedido, no idioma
/// atual da app.
String buildReportMessage({
  required Client client,
  required PaymentCycleGroup cycle,
  required AppStrings strings,
  String providerName = '',
}) {
  final sortedSessions = [...cycle.sessions]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  final sessionDatesLabel = sortedSessions.map((s) => _formatDayMonth(s.scheduledFor)).join(', ');
  // Mesmo formato usado em todo o resto da app (ex.: Pagamentos, Ficha do
  // aluno) — evita a mensagem do relatório mostrar um separador decimal
  // diferente do cabeçalho do diálogo que a antecede.
  final totalLabel = '${cycle.totalAmount.toStringAsFixed(2)}€';

  final subjectName = client.serviceType.trim().isNotEmpty ? client.serviceType.trim() : client.name;
  final labels = getLabels(client.activityType, strings.language);

  return strings.reportMessage(
    subjectName: subjectName,
    sessionDatesLabel: sessionDatesLabel.isEmpty ? strings.dash : sessionDatesLabel,
    totalSessions: cycle.totalSessions,
    totalAmountLabel: totalLabel,
    sessionPluralLower: labels.sessionPlural.toLowerCase(),
    masculine: labels.sessionIsMasculine,
    providerName: providerName.trim(),
  );
}

/// O link do WhatsApp (wa.me) exige o número completo com indicativo de país.
/// Se o utilizador não incluir indicativo (ex.: escreveu só o nº de telemóvel
/// português de 9 dígitos), assume-se Portugal (+351) por ser o caso mais
/// comum nesta app — caso já tenha "+"/"00" ou mais dígitos, respeita-se tal
/// como está.
String normalizePhoneForWhatsApp(String rawPhone) {
  final withPlus = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');

  final String digitsOnly;
  if (withPlus.startsWith('+')) {
    digitsOnly = withPlus.substring(1).replaceAll('+', '');
  } else if (withPlus.startsWith('00')) {
    digitsOnly = withPlus.substring(2).replaceAll('+', '');
  } else {
    digitsOnly = withPlus.replaceAll('+', '');
  }

  if (digitsOnly.length == 9) return '351$digitsOnly';
  return digitsOnly;
}

Future<bool> sendViaWhatsApp(String phone, String message) async {
  final digits = normalizePhoneForWhatsApp(phone);
  final uri = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

Future<bool> sendViaEmail(String email, String subject, String message) async {
  // Uri(...queryParameters: {...}) codifica espaços como "+" (estilo
  // application/x-www-form-urlencoded); um mailto: precisa de codificação
  // percentual (RFC 6068) — caso contrário, muitos clientes de email mostram
  // o "+" literal em vez de espaço no assunto/corpo. Uri.encodeComponent usa
  // %20, por isso constrói-se a query manualmente.
  final uri = Uri.parse(
    'mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(message)}',
  );
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  return false;
}
