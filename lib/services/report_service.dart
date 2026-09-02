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
}) {
  final sortedSessions = [...cycle.sessions]..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  final sessionDatesLabel = sortedSessions.map((s) => _formatDayMonth(s.scheduledFor)).join(', ');
  final totalLabel = '${cycle.totalAmount.toStringAsFixed(2).replaceAll('.', ',')}€';

  final subjectName = client.serviceType.trim().isNotEmpty ? client.serviceType.trim() : client.name;

  return strings.reportMessage(
    subjectName: subjectName,
    sessionDatesLabel: sessionDatesLabel.isEmpty ? strings.dash : sessionDatesLabel,
    totalSessions: cycle.totalSessions,
    totalAmountLabel: totalLabel,
  );
}

Future<bool> sendViaWhatsApp(String phone, String message) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final uri = Uri.parse('https://wa.me/$digits?text=${Uri.encodeComponent(message)}');
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

Future<bool> sendViaEmail(String email, String subject, String message) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
    queryParameters: {
      'subject': subject,
      'body': message,
    },
  );
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  return false;
}
