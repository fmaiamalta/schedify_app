/// Normaliza um número vindo dos Contactos para o formato aceite pelo
/// validador do telefone no formulário (`^\+?\d+$`): remove espaços,
/// parênteses, hífens, etc., mantendo apenas um eventual '+' inicial tal
/// como veio do contacto.
///
/// Ao contrário de `normalizePhoneForWhatsApp` (em report_service.dart),
/// esta função não adivinha o indicativo de país nem remove o '+' — o
/// resultado fica visível e editável no campo do formulário, por isso tem
/// de continuar a parecer-se com o que a pessoa reconhece.
String normalizeImportedPhone(String raw) {
  final trimmed = raw.trim();
  final hasLeadingPlus = trimmed.startsWith('+');
  final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) return '';
  return hasLeadingPlus ? '+$digitsOnly' : digitsOnly;
}

/// Se o telefone escrito à mão não tiver indicativo de país (sem '+') e
/// tiver exatamente 9 dígitos, assume Portugal (+351) — o mesmo critério já
/// usado em normalizePhoneForWhatsApp (report_service.dart), aplicado agora
/// também ao que fica guardado, não só ao enviar por WhatsApp. Sem isto, um
/// cliente que ignore a dica "inclua o indicativo" fica com um número
/// tecnicamente incompleto guardado no seu registo.
String ensureCountryCode(String phone) {
  final trimmed = phone.trim();
  if (trimmed.isEmpty || trimmed.startsWith('+')) return trimmed;
  final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.length == 9) return '+351$digitsOnly';
  return trimmed;
}
