import 'package:flutter/material.dart';

enum ActivityType {
  education,
  fitness,
  health,
  otherServices,
}

enum AppLanguage {
  pt,
  en,
}

/// Idioma atual da app, à escala global — necessário para que widgets nativos
/// (ex.: showDatePicker) sigam o idioma escolhido nas Definições, já que esse
/// idioma é um conceito próprio da app (AppLanguage), não a "Locale" do
/// dispositivo. Atualizado sempre que o idioma muda (arranque e Definições),
/// e lido pelo MaterialApp em SchedifyApp para definir a sua `locale`.
final ValueNotifier<AppLanguage> currentAppLanguage = ValueNotifier(AppLanguage.pt);

Locale localeFor(AppLanguage language) => Locale(language == AppLanguage.en ? 'en' : 'pt');

/// Frequência de pagamento (ciclo de acumulação/relatório em Pagamentos).
enum PaymentType {
  avulso,
  semanal,
  mensal,
}

/// Forma como o valor de uma sessão é calculado: por hora (proporcional à
/// duração) ou um valor total fixo por sessão (ex.: um projeto Avulso).
enum RateType {
  perHour,
  total,
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
  final bool flatRate; // true = valor fixo por sessão, false = valor por hora

  /// Género gramatical de [sessionSingular]/[sessionPlural] em português —
  /// "Aula"/"Consulta"/"Sessão" são femininas, mas "Treino"/"Treinos"
  /// (Fitness) é masculino. Usado para concordar corretamente particípios
  /// como "registada(s)"/"registado(s)" nas strings que os incluem.
  final bool sessionIsMasculine;

  /// Género gramatical de [serviceTypeLabel] em português — "Disciplina"/
  /// "Modalidade"/"Especialidade" são femininas, mas "Serviço" (Outros
  /// Serviços) é masculino.
  final bool serviceTypeIsMasculine;

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
    required this.flatRate,
    this.sessionIsMasculine = false,
    this.serviceTypeIsMasculine = false,
  });
}

ActivityLabels getLabels(ActivityType type, [AppLanguage language = AppLanguage.pt]) {
  final isEn = language == AppLanguage.en;

  switch (type) {
    case ActivityType.education:
      return ActivityLabels(
        areaName: isEn ? 'Education' : 'Educação',
        clientSingular: isEn ? 'Student' : 'Aluno/Formando',
        clientPlural: isEn ? 'Students' : 'Alunos/Formandos',
        sessionSingular: isEn ? 'Class' : 'Aula',
        sessionPlural: isEn ? 'Classes' : 'Aulas',
        serviceTypeLabel: isEn ? 'Subject' : 'Disciplina',
        durationLabel: isEn ? 'Class duration' : 'Duração da aula',
        frequencyLabel: isEn ? 'Class frequency' : 'Frequência da aula',
        rateLabel: isEn ? 'Rate per hour (€)' : 'Valor por hora (€)',
        flatRate: false,
        sessionIsMasculine: false,
        serviceTypeIsMasculine: false,
      );
    case ActivityType.fitness:
      return ActivityLabels(
        areaName: isEn ? 'Fitness' : 'Fitness',
        clientSingular: isEn ? 'Client' : 'Aluno',
        clientPlural: isEn ? 'Clients' : 'Alunos',
        sessionSingular: isEn ? 'Workout' : 'Treino',
        sessionPlural: isEn ? 'Workouts' : 'Treinos',
        serviceTypeLabel: isEn ? 'Activity / Service' : 'Modalidade / Serviço',
        durationLabel: isEn ? 'Workout duration' : 'Duração do treino',
        frequencyLabel: isEn ? 'Workout frequency' : 'Frequência do treino',
        rateLabel: isEn ? 'Rate per hour (€)' : 'Valor por hora (€)',
        flatRate: false,
        sessionIsMasculine: true,
        serviceTypeIsMasculine: false, // "Modalidade / Serviço" -> palavra pública é "Modalidade"
      );
    case ActivityType.health:
      return ActivityLabels(
        areaName: isEn ? 'Health' : 'Saúde',
        clientSingular: isEn ? 'Patient' : 'Utente/Paciente',
        clientPlural: isEn ? 'Patients' : 'Utentes/Pacientes',
        sessionSingular: isEn ? 'Appointment' : 'Consulta',
        sessionPlural: isEn ? 'Appointments' : 'Consultas',
        serviceTypeLabel: isEn ? 'Specialty / Appointment type' : 'Especialidade / Tipo de consulta',
        durationLabel: isEn ? 'Appointment duration' : 'Duração da consulta',
        frequencyLabel: isEn ? 'Appointment frequency' : 'Frequência da consulta',
        rateLabel: isEn ? 'Appointment fee (€)' : 'Valor da consulta (€)',
        flatRate: true,
      );
    case ActivityType.otherServices:
      return ActivityLabels(
        areaName: isEn ? 'Other Services' : 'Outros Serviços',
        clientSingular: isEn ? 'Client' : 'Cliente',
        clientPlural: isEn ? 'Clients' : 'Clientes',
        sessionSingular: isEn ? 'Session' : 'Sessão',
        sessionPlural: isEn ? 'Sessions' : 'Sessões',
        serviceTypeLabel: isEn ? 'Service' : 'Serviço',
        durationLabel: isEn ? 'Session duration' : 'Duração da sessão',
        frequencyLabel: isEn ? 'Session frequency' : 'Frequência da sessão',
        rateLabel: isEn ? 'Rate per hour (€)' : 'Valor por hora (€)',
        flatRate: false,
        serviceTypeIsMasculine: true, // "Serviço"
      );
  }
}

/// Usa só a primeira palavra/segmento de nomenclaturas compostas (ex.:
/// "Alunos/Formandos" → "Alunos", "Especialidade / Tipo de consulta" →
/// "Especialidade"), para caber em espaços apertados como a barra de
/// navegação inferior ou o título de um AppBar.
String shortCompoundLabel(String label) => label.split('/').first.trim();

String paymentTypeLabel(PaymentType type, [AppLanguage language = AppLanguage.pt]) {
  final isEn = language == AppLanguage.en;
  switch (type) {
    case PaymentType.avulso:
      return isEn ? 'One-off' : 'Avulso';
    case PaymentType.semanal:
      return isEn ? 'Weekly' : 'Semanal';
    case PaymentType.mensal:
      return isEn ? 'Monthly' : 'Mensal';
  }
}

/// Um dia da semana + hora, associado a um aluno/cliente. `weekday` segue a
/// convenção de [DateTime.weekday] (1 = segunda ... 7 = domingo).
class WeeklySlot {
  final int weekday;
  final TimeOfDay time;

  const WeeklySlot({required this.weekday, required this.time});

  WeeklySlot copyWith({int? weekday, TimeOfDay? time}) {
    return WeeklySlot(
      weekday: weekday ?? this.weekday,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'hour': time.hour,
        'minute': time.minute,
      };

  factory WeeklySlot.fromJson(Map<String, dynamic> json) => WeeklySlot(
        weekday: json['weekday'] as int,
        time: TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int),
      );
}

/// Exceção pontual ao horário fixo de um cliente: move ou cancela uma única
/// ocorrência (ex.: "esta segunda em particular passou para quarta"), sem
/// alterar o padrão semanal/mensal que continua a gerar todas as outras.
/// [originalScheduledFor] é a data+hora que o padrão teria produzido nesse
/// dia (congelada no momento da ação, para conseguir mostrar/reverter mais
/// tarde); [newDateTime] é `null` quando a ocorrência foi cancelada, ou a
/// nova data+hora quando foi só reagendada.
class OccurrenceOverride {
  final DateTime originalScheduledFor;
  final DateTime? newDateTime;

  const OccurrenceOverride({required this.originalScheduledFor, this.newDateTime});

  bool get isCancelled => newDateTime == null;

  Map<String, dynamic> toJson() => {
        'originalScheduledFor': originalScheduledFor.toIso8601String(),
        'newDateTime': newDateTime?.toIso8601String(),
      };

  factory OccurrenceOverride.fromJson(Map<String, dynamic> json) => OccurrenceOverride(
        originalScheduledFor: DateTime.parse(json['originalScheduledFor'] as String),
        newDateTime: json['newDateTime'] != null ? DateTime.parse(json['newDateTime'] as String) : null,
      );
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
  final List<WeeklySlot> slots;

  /// Data de início da série (apenas a componente de data é relevante).
  final DateTime startDate;

  /// Data de fim da série. `null` = sem data de fim.
  final DateTime? endDate;

  final double hourlyRate;
  final RateType rateType;
  final bool hasVat;
  final PaymentType paymentType;

  /// Tipo de atividade em vigor quando este aluno/cliente foi criado — usado
  /// para o distinguir visualmente (cor) se o tipo global for alterado depois.
  final ActivityType activityType;

  /// Exceções pontuais ao horário fixo (ver [OccurrenceOverride]) — no
  /// máximo uma por dia original. Por omissão vazia: não é `required` de
  /// propósito, para não obrigar a tocar em todos os sítios que já
  /// constroem `Client(...)` diretamente (formulário, testes) só por causa
  /// desta funcionalidade.
  final List<OccurrenceOverride> occurrenceOverrides;

  Client({
    required this.id,
    required this.name,
    required this.serviceType,
    required this.contactEmail,
    required this.contactPhone,
    required this.notes,
    required this.sessionDurationMinutes,
    required this.sessionFrequency,
    required this.slots,
    required this.startDate,
    required this.endDate,
    required this.hourlyRate,
    required this.rateType,
    required this.hasVat,
    required this.paymentType,
    required this.activityType,
    this.occurrenceOverrides = const [],
  });

  Client copyWith({
    String? name,
    String? serviceType,
    String? contactEmail,
    String? contactPhone,
    String? notes,
    int? sessionDurationMinutes,
    String? sessionFrequency,
    List<WeeklySlot>? slots,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    double? hourlyRate,
    RateType? rateType,
    bool? hasVat,
    PaymentType? paymentType,
    ActivityType? activityType,
    List<OccurrenceOverride>? occurrenceOverrides,
  }) {
    return Client(
      id: id,
      name: name ?? this.name,
      serviceType: serviceType ?? this.serviceType,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      notes: notes ?? this.notes,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      sessionFrequency: sessionFrequency ?? this.sessionFrequency,
      slots: slots ?? this.slots,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rateType: rateType ?? this.rateType,
      hasVat: hasVat ?? this.hasVat,
      paymentType: paymentType ?? this.paymentType,
      activityType: activityType ?? this.activityType,
      occurrenceOverrides: occurrenceOverrides ?? this.occurrenceOverrides,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'serviceType': serviceType,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'notes': notes,
        'sessionDurationMinutes': sessionDurationMinutes,
        'sessionFrequency': sessionFrequency,
        'slots': slots.map((s) => s.toJson()).toList(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'hourlyRate': hourlyRate,
        'rateType': rateType.name,
        'hasVat': hasVat,
        'paymentType': paymentType.name,
        'activityType': activityType.name,
        'occurrenceOverrides': occurrenceOverrides.map((o) => o.toJson()).toList(),
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        id: json['id'] as String,
        name: json['name'] as String,
        serviceType: json['serviceType'] as String,
        contactEmail: json['contactEmail'] as String,
        contactPhone: json['contactPhone'] as String,
        notes: json['notes'] as String? ?? '',
        sessionDurationMinutes: json['sessionDurationMinutes'] as int,
        sessionFrequency: json['sessionFrequency'] as String,
        slots: (json['slots'] as List<dynamic>).map((s) => WeeklySlot.fromJson(s as Map<String, dynamic>)).toList(),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
        hourlyRate: (json['hourlyRate'] as num).toDouble(),
        rateType: RateType.values.byName(json['rateType'] as String? ?? 'perHour'),
        hasVat: json['hasVat'] as bool,
        paymentType: PaymentType.values.byName(json['paymentType'] as String),
        activityType: ActivityType.values.byName(json['activityType'] as String? ?? 'education'),
        occurrenceOverrides: (json['occurrenceOverrides'] as List<dynamic>?)
                ?.map((o) => OccurrenceOverride.fromJson(o as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class SessionRecord {
  final String id;
  final String clientId;
  final DateTime registeredAt;
  final DateTime scheduledFor;
  final int durationMinutes;
  final double amount;
  final bool isPaid;
  final String notes;

  SessionRecord({
    required this.id,
    required this.clientId,
    required this.registeredAt,
    required this.scheduledFor,
    required this.durationMinutes,
    required this.amount,
    this.isPaid = false,
    this.notes = '',
  });

  SessionRecord copyWith({bool? isPaid}) {
    return SessionRecord(
      id: id,
      clientId: clientId,
      registeredAt: registeredAt,
      scheduledFor: scheduledFor,
      durationMinutes: durationMinutes,
      amount: amount,
      isPaid: isPaid ?? this.isPaid,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'registeredAt': registeredAt.toIso8601String(),
        'scheduledFor': scheduledFor.toIso8601String(),
        'durationMinutes': durationMinutes,
        'amount': amount,
        'isPaid': isPaid,
        'notes': notes,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        registeredAt: DateTime.parse(json['registeredAt'] as String),
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        durationMinutes: json['durationMinutes'] as int,
        amount: (json['amount'] as num).toDouble(),
        isPaid: json['isPaid'] as bool? ?? false,
        notes: json['notes'] as String? ?? '',
      );
}

/// Uma ocorrência planeada (ainda não registada) de uma sessão para um
/// cliente. [originalScheduledFor] é a data+hora que o horário fixo geraria
/// nesse dia — normalmente igual a [scheduledFor], exceto quando existe um
/// [OccurrenceOverride] a mover essa ocorrência (nesse caso é a "chave" para
/// criar/substituir/reverter o override). [isCancelled] marca uma linha
/// "fantasma" no dia original de uma ocorrência cancelada, só para dar
/// forma de a reagendar/reverter mais tarde.
class PlannedOccurrence {
  final Client client;
  final DateTime scheduledFor;
  final DateTime originalScheduledFor;
  final bool isCancelled;

  const PlannedOccurrence({
    required this.client,
    required this.scheduledFor,
    DateTime? originalScheduledFor,
    this.isCancelled = false,
  }) : originalScheduledFor = originalScheduledFor ?? scheduledFor;

  bool get isMoved => !isCancelled && originalScheduledFor != scheduledFor;
}
