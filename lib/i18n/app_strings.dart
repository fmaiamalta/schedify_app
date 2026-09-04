import '../models.dart';

/// Todas as strings de interface fixas da app (fora do vocabulário dinâmico já
/// tratado por [ActivityLabels]), em pt-PT e inglês.
class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  bool get _en => language == AppLanguage.en;
  String _t(String pt, String en) => _en ? en : pt;

  // Ecrã inicial
  String get chooseActivityTitle => _t('Escolha o tipo de atividade', 'Choose the type of activity');
  String get chooseActivitySubtitle => _t(
        'A app adapta automaticamente as nomenclaturas à área profissional escolhida. Pode ser alterado mais tarde nas Definições.',
        'The app automatically adapts the wording to the chosen professional area. This can be changed later in Settings.',
      );

  // Navegação inferior
  String get navHome => _t('Início', 'Home');
  String get navPayments => _t('Pagamentos', 'Payments');

  // Dashboard
  String get dashboard => _t('Dashboard', 'Dashboard');
  String get quickActions => _t('Ações rápidas', 'Quick actions');
  String newLabel(String noun) => _t('Novo $noun', 'New $noun');
  String registerLabel(String noun) => _t('Registar $noun', 'Register $noun');
  String get schedule => _t('Horário', 'Schedule');
  String upcomingThisWeek(String sessionPlural) => _t('Próximas $sessionPlural (esta semana)', 'Upcoming $sessionPlural (this week)');
  String noneScheduledThisWeek(String sessionPluralLower) =>
      _t('Não há $sessionPluralLower previstas para o resto desta semana.', 'No $sessionPluralLower planned for the rest of this week.');
  String get statistics => _t('Estatísticas', 'Statistics');
  String get paymentsReceived => _t('Pagamentos efetuados', 'Payments received');
  String registeredCountLabel(int count) => _t('$count registos efetuados', '$count records made');
  String get thisActivityFilter => _t('Nesta atividade', 'This activity');
  String get allEnrolledFilter => _t('Todos', 'All');
  String get allEnrolledTitle => _t('Todos os Inscritos', 'All Enrolled');
  String get allActivitiesTitle => _t('Todas as Atividades', 'All Activities');
  String get allPaymentsTitle => _t('Todos os Pagamentos', 'All Payments');

  // Registar sessão (ecrã) — esta lista mistura ocorrências de todas as
  // atividades em uso (não só da área de trabalho atual), por isso o título
  // e o subtítulo não podem assumir um único nome de sessão; cada item da
  // lista mostra o nome correto (ver register_screen.dart).
  String get registerableSubtitle => _t(
        'O que está agendado para hoje ou até 1 semana atrás, ainda por registar.',
        "What's scheduled for today or up to 1 week ago, still to register.",
      );
  String get nothingToRegister => _t('Nada por registar.', 'Nothing to register.');
  String get registerButton => _t('Registar', 'Register');
  String registeredSnackbar(String sessionSingular, String name, {bool masculine = false}) =>
      _t('$sessionSingular ${masculine ? 'registado' : 'registada'} para $name', '$sessionSingular registered for $name');
  String get undo => _t('Anular', 'Undo');

  // Alunos / lista de clientes
  String countRegistered(int count) => _t('$count registados', '$count registered');
  String noneRegisteredYet(String clientPluralLower) =>
      _t('Ainda não há $clientPluralLower registados', 'No $clientPluralLower yet');
  String startByAdding(String clientSingularLower) => _t(
        'Comece por adicionar o primeiro $clientSingularLower com a respetiva configuração base.',
        'Start by adding the first $clientSingularLower with their basic setup.',
      );

  // Disciplinas / subjects
  String subjectsCreated(int count, {bool masculine = false}) =>
      _t('$count ${masculine ? 'registados' : 'registadas'}', '$count registered');
  String noSubjectsYet(String serviceTypeLower, String clientSingularLower) => _t(
        'Ainda não há $serviceTypeLower criadas.\nSão criadas automaticamente ao adicionar um(a) $clientSingularLower.',
        'No $serviceTypeLower yet.\nThey are created automatically when you add a $clientSingularLower.',
      );
  String enrolledCount(int count, String clientPluralLower) => _t('$count $clientPluralLower inscrito(s)', '$count $clientPluralLower enrolled');
  String get close => _t('Fechar', 'Close');

  // Horário (calendário)
  List<String> get monthNames => _en
      ? const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
      : const ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
  List<String> get weekdayShortHeader => _en ? const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] : const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  String weekdayShort(int weekday) {
    const pt = {1: 'Seg', 2: 'Ter', 3: 'Qua', 4: 'Qui', 5: 'Sex', 6: 'Sáb', 7: 'Dom'};
    const en = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return (_en ? en : pt)[weekday] ?? '';
  }

  String weekdayFull(int weekday) {
    const pt = {1: 'Segunda-feira', 2: 'Terça-feira', 3: 'Quarta-feira', 4: 'Quinta-feira', 5: 'Sexta-feira', 6: 'Sábado', 7: 'Domingo'};
    const en = {1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday'};
    return (_en ? en : pt)[weekday] ?? '';
  }

  // Reagendar/cancelar uma única ocorrência (Horário)
  String rescheduleAction(String sessionSingularLower) => _t('Reagendar $sessionSingularLower', 'Reschedule $sessionSingularLower');
  String cancelOccurrenceAction(String sessionSingularLower) => _t('Cancelar $sessionSingularLower', 'Cancel $sessionSingularLower');
  String get revertOccurrenceAction => _t('Reverter ao horário normal', 'Revert to normal schedule');
  String cancelledBadgeLabel({bool masculine = false}) => _t(masculine ? 'Cancelado' : 'Cancelada', 'Cancelled');
  String confirmCancelOccurrenceTitle(String sessionSingularLower) =>
      _t('Cancelar ${sessionSingularLower.trim()}?', 'Cancel $sessionSingularLower?');
  String confirmCancelOccurrenceBody(String sessionSingularLower, String name, String dateLabel, {bool masculine = false}) => _t(
        '${masculine ? 'Este' : 'Esta'} $sessionSingularLower de $name em $dateLabel fica ${masculine ? 'cancelado' : 'cancelada'}. '
        'Podes reverter mais tarde.',
        'This $sessionSingularLower for $name on $dateLabel will be cancelled. You can revert later.',
      );
  String occurrenceRescheduledSnackbar(String sessionSingular, String name, String newDateLabel, {bool masculine = false}) => _t(
        '$sessionSingular de $name ${masculine ? 'movido' : 'movida'} para $newDateLabel.',
        '$sessionSingular for $name moved to $newDateLabel.',
      );
  String occurrenceCancelledSnackbar(String sessionSingular, String name, {bool masculine = false}) => _t(
        '$sessionSingular de $name ${masculine ? 'cancelado' : 'cancelada'}.',
        '$sessionSingular for $name cancelled.',
      );
  String occurrenceRevertedSnackbar(String name) => _t('Horário normal reposto para $name.', 'Normal schedule restored for $name.');

  // Pagamentos
  String get paymentsTitle => _t('Pagamentos', 'Payments');
  String get pending => _t('Pendentes', 'Pending');
  String get completed => _t('Efetuados', 'Completed');
  String get noPendingPayments => _t('Sem pagamentos pendentes.', 'No pending payments.');
  String get noCompletedPayments => _t('Ainda não há pagamentos efetuados.', 'No completed payments yet.');
  String get cycleClosed => _t('Ciclo fechado', 'Cycle closed');
  String get accumulating => _t('A acumular', 'Accumulating');
  String get cycleStillAccumulating => _t('O ciclo ainda está a acumular.', 'The cycle is still accumulating.');
  String get clear => _t('Limpar', 'Clear');
  String get report => _t('Relatório', 'Report');
  String get confirmPaymentTitle => _t('Confirmar pagamento', 'Confirm payment');
  String confirmPaymentBody(String name, String period) =>
      _t('Marcar o pagamento de $name ($period) como efetuado?', 'Mark the payment for $name ($period) as completed?');
  String paymentMarkedPaidSnackbar(String name, String period) =>
      _t('Pagamento de $name ($period) marcado como efetuado.', 'Payment for $name ($period) marked as completed.');
  String get cancel => _t('Cancelar', 'Cancel');
  String get done => _t('Concluir', 'Done');
  String get discardChangesTitle => _t('Descartar alterações?', 'Discard changes?');
  String get discardChangesBody =>
      _t('Ainda não guardaste este formulário. Se saíres agora, perdes o que preencheste.',
          'You haven\'t saved this form yet. If you leave now, what you filled in will be lost.');
  String get discard => _t('Descartar', 'Discard');
  String get confirm => _t('Confirmar', 'Confirm');
  String get clearRecordTitle => _t('Limpar registo', 'Clear record');
  String clearRecordBody(String name, String period) => _t(
        'Remover definitivamente o pagamento de $name ($period) do histórico?',
        'Permanently remove the payment for $name ($period) from history?',
      );
  String reportTitle(String name) => _t('Relatório — $name', 'Report — $name');
  String reportSummary(int count, String sessionPluralLower, String amount) =>
      _t('$count $sessionPluralLower · $amount', '$count $sessionPluralLower · $amount');
  String get whatsapp => 'WhatsApp';
  String get email => _t('Email', 'Email');
  String get whatsappOpenFailed => _t('Não foi possível abrir o WhatsApp.', 'Could not open WhatsApp.');
  String get emailOpenFailed => _t('Não foi possível abrir o cliente de email.', 'Could not open the email client.');
  String get reportNotSentWarning => _t(
        'Ainda não enviaste o relatório deste período. Podes marcar como pago à mesma.',
        'You haven\'t sent the report for this period yet. You can still mark it as paid.',
      );
  String get globalSummary => _t('Resumo Global', 'Global summary');

  // Definições
  String get settingsTitle => _t('Definições', 'Settings');
  String get activityTypeTitle => _t('Tipo de atividade', 'Activity type');
  String get activityTypeSubtitle => _t('Determina a nomenclatura usada em toda a aplicação.', 'Determines the wording used throughout the app.');
  String get languageTitle => _t('Idioma', 'Language');
  String get languageSubtitle => _t('Idioma usado em toda a aplicação.', 'Language used throughout the app.');
  String get portuguese => 'Português';
  String get english => 'English';
  String get dataSection => _t('Dados', 'Data');
  String get backupTitle => _t('Fazer backup da informação', 'Back up information');
  String get backupSubtitle => _t('Cópia de segurança dos dados na nuvem.', 'Cloud backup of your data.');
  String get premium => 'PREMIUM';
  String get about => _t('Acerca', 'About');
  String get version => _t('Versão', 'Version');
  String get developedBy => _t('Desenvolvido por Spiga', 'Developed by Spiga');

  // Novo Aluno / formulário
  String editNoun(String noun) => _t('Editar $noun', 'Edit $noun');
  String get edit => _t('Editar', 'Edit');
  String get save => _t('Guardar', 'Save');

  // Eliminar aluno/cliente (Ficha do aluno) e estado "inativo" (Alunos/Disciplina)
  String deleteClientAction(String clientSingularLower) => _t('Eliminar $clientSingularLower', 'Delete $clientSingularLower');
  String confirmDeleteClientTitle(String clientSingularLower) => _t('Eliminar $clientSingularLower?', 'Delete $clientSingularLower?');
  String confirmDeleteClientBody(String name) => _t(
        'Todo o histórico de sessões e pagamentos de $name é eliminado permanentemente. Esta ação não pode ser desfeita.',
        'All session and payment history for $name is permanently deleted. This action cannot be undone.',
      );
  String clientDeletedSnackbar(String clientSingular, String name) =>
      _t('$clientSingular $name eliminado.', '$clientSingular $name deleted.');
  String get inactiveBadgeLabel => _t('Inativo', 'Inactive');
  String infoSection(String noun) => _t('Informações do $noun', 'Information for $noun');
  String sessionConfigSection(String sessionSingularLower, {bool masculine = false}) =>
      _t('Configuração ${masculine ? 'do' : 'da'} $sessionSingularLower', 'Configuration of $sessionSingularLower');
  String get paymentConfigSection => _t('Configuração do pagamento', 'Payment configuration');
  String get nameLabel => _t('Nome', 'Name');
  String get emailLabel => _t('Email', 'Email');
  String get phoneLabel => _t('Telefone', 'Phone');
  String get phoneHint => _t(
        'Inclua o indicativo do país (ex.: +351) para o WhatsApp funcionar bem.',
        'Include the country code (e.g. +1) for WhatsApp to work correctly.',
      );
  String get notesLabel => _t('Notas', 'Notes');
  String newSubject(String subjectLower) => _t('Nova $subjectLower', 'New $subjectLower');
  String get startDateLabel => _t('Data de início', 'Start date');
  String get endDateLabel => _t('Data de fim', 'End date');
  String get noEndDateLabel => _t('Sem data de fim', 'No end date');
  String get dateTimeLabel => _t('Data e hora', 'Date and time');
  String hourFor(String weekdayLabel) => _t('Hora — $weekdayLabel', 'Time — $weekdayLabel');
  String get paymentFrequencyLabel => _t('Frequência de pagamento', 'Payment frequency');
  String get perHourOption => _t('Por hora', 'Per hour');
  String get totalOption => _t('Total', 'Total');
  String get rateLabelPerHour => _t('Valor por hora (€)', 'Rate per hour (€)');
  String get rateLabelTotal => _t('Valor total (€)', 'Total value (€)');
  String get vatSwitchLabel => _t('Com IVA', 'VAT included');
  String scheduleHint(String sessionPluralLower, {bool masculine = false}) => _t(
        'A escolha da frequência reflete-se automaticamente no calendário e ${masculine ? 'nos' : 'nas'} '
        '$sessionPluralLower ${masculine ? 'previstos' : 'previstas'}.',
        'The chosen frequency is automatically reflected in the calendar and planned $sessionPluralLower.',
      );
  String minutesOption(int minutes) => _t('$minutes minutos', '$minutes minutes');
  String get customDurationOption => _t('Personalizado', 'Custom');
  String get customDurationFieldLabel => _t('Duração personalizada (minutos)', 'Custom duration (minutes)');
  String weekdaysCount(int count) => _t('Dias da semana ($count)', 'Days of the week ($count)');
  String get requiredField => _t('Campo obrigatório', 'Required field');
  String get invalidCharacters => _t('Carateres inválidos', 'Invalid characters');
  String get atLeastOneContact => _t('É necessário pelo menos um contacto', 'At least one contact is required');
  String get invalidEmail => _t('Email inválido', 'Invalid email');
  String get numbersOnly => _t('Apenas números', 'Numbers only');
  String get invalidValue => _t('Valor inválido', 'Invalid value');
  String selectExactlyDays(int count) => _t('Selecione exatamente $count dia(s) para esta frequência.', 'Select exactly $count day(s) for this frequency.');
  String get indicateEndDate => _t('Indique a data de fim ou ative "Sem data de fim".', 'Enter the end date or enable "No end date".');
  String startDateError(String detail) => _t('Data de início: $detail', 'Start date: $detail');
  String endDateError(String detail) => _t('Data de fim: $detail', 'End date: $detail');
  String weekdayMismatch(String date, String actualWeekday, String allowedWeekdays) => _t(
        'A data $date cai numa $actualWeekday, mas os dias escolhidos são: $allowedWeekdays.',
        'The date $date falls on a $actualWeekday, but the chosen days are: $allowedWeekdays.',
      );

  // Ficha do aluno
  String get info => _t('Informações', 'Information');
  String get durationLabel => _t('Duração', 'Duration');
  String get frequencyLabel => _t('Frequência', 'Frequency');
  String get scheduleLabel => _t('Horário', 'Schedule');
  String get startLabel => _t('Início', 'Start');
  String get endLabel => _t('Fim', 'End');
  String get valueLabel => _t('Valor', 'Value');
  String get vatLabel => _t('IVA', 'VAT');
  String get paymentLabel => _t('Pagamento', 'Payment');
  String get yes => _t('Sim', 'Yes');
  String get no => _t('Não', 'No');
  String get dash => '—';
  String noneRecordedYet(String sessionPluralLower, {bool masculine = false}) =>
      _t('Ainda não há $sessionPluralLower ${masculine ? 'registados' : 'registadas'}.', 'No $sessionPluralLower recorded yet.');
  String get minutesAbbrev => _t('min', 'min');
  String paidLabel({bool masculine = false}) => _t(masculine ? 'Pago' : 'Paga', 'Paid');
  String get pendingBadge => _t('Pendente', 'Pending');

  // Mensagem de relatório (WhatsApp / Email)
  String reportMessage({
    required String subjectName,
    required String sessionDatesLabel,
    required int totalSessions,
    required String totalAmountLabel,
    required String sessionPluralLower,
    bool masculine = false,
  }) {
    if (_en) {
      return 'Hello,\n'
          'Here is the summary for $subjectName:\n'
          'Summary: $sessionDatesLabel.\n'
          'Total number of $sessionPluralLower: $totalSessions\n'
          'Total to pay: $totalAmountLabel\n'
          'Best regards.';
    }
    return 'Olá,\n'
        'Segue o resumo ${masculine ? 'dos' : 'das'} $sessionPluralLower de $subjectName:\n'
        'Resumo: $sessionDatesLabel.\n'
        'Número total de $sessionPluralLower: $totalSessions\n'
        'Total a pagar: $totalAmountLabel\n'
        'Cumprimentos.';
  }
}

/// Nomes de frequência de sessão apresentados no formulário — o valor
/// interno guardado é sempre em português (chave estável), a etiqueta
/// mostrada muda com o idioma.
const List<String> kSessionFrequencyKeys = ['Avulso', 'Semanal', '2x por semana', '3x por semana', 'Quinzenal', 'Mensal'];

String sessionFrequencyLabel(String key, AppLanguage language) {
  if (language != AppLanguage.en) return key;
  const map = {
    'Avulso': 'One-off',
    'Semanal': 'Weekly',
    '2x por semana': '2x per week',
    '3x por semana': '3x per week',
    'Quinzenal': 'Biweekly',
    'Mensal': 'Monthly',
  };
  return map[key] ?? key;
}
