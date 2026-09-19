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
