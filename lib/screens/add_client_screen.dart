import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../services/schedule_logic.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';

/// Só a primeira letra (não title case) — usado em Nome/Disciplina/Notas ao
/// guardar, para que o registo fique arrumado mesmo que o utilizador tenha
/// escrito tudo em minúsculas.
String _capitalizeFirstLetter(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

class AddClientScreen extends StatefulWidget {
  final ActivityType activityType;
  final AppLanguage language;
  final Client? existingClient;

  const AddClientScreen({
    super.key,
    required this.activityType,
    required this.language,
    this.existingClient,
  });

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _serviceTypeController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;
  late final TextEditingController _hourlyRateController;

  static const _presetDurations = [30, 45, 60, 90];
  static const _customDurationSentinel = -1;

  late int _sessionDurationMinutes;
  late bool _customDuration;
  late final TextEditingController _customDurationController;
  final _customDurationFocus = FocusNode();
  late String _sessionFrequency;

  // Para frequências recorrentes (tudo exceto Avulso).
  List<int> _selectedWeekdays = [];
  Map<int, TimeOfDay> _slotTimes = {};
  late DateTime _startDate;
  DateTime? _endDate;
  bool _noEndDate = true;

  // Apenas para Avulso: uma única data+hora.
  late DateTime _avulsoDateTime;

  bool _hasVat = false;
  late PaymentType _paymentType;
  late RateType _rateType;
  late ActivityType _clientActivityType;

  bool get _isEditing => widget.existingClient != null;

  ActivityLabels get labels => getLabels(_clientActivityType, widget.language);
  AppStrings get s => AppStrings(widget.language);

  @override
  void initState() {
    super.initState();
    final existing = widget.existingClient;
    final now = DateTime.now();

    _clientActivityType = existing?.activityType ?? widget.activityType;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _serviceTypeController = TextEditingController(
      text: existing?.serviceType ?? '',
    );
    _emailController = TextEditingController(
      text: existing?.contactEmail ?? '',
    );
    _phoneController = TextEditingController(
      text: existing?.contactPhone ?? '',
    );
    _notesController = TextEditingController(text: existing?.notes ?? '');
    _hourlyRateController = TextEditingController(
      text: existing != null ? existing.hourlyRate.toStringAsFixed(2) : '',
    );

    // Reconstrói sempre que um destes campos muda, para que a verificação de
    // alterações por guardar (usada pelo PopScope, ver _hasUnsavedChanges)
    // fique sempre atualizada — TextEditingController não avisa sozinho o
    // State pai quando o texto muda.
    for (final controller in [
      _nameController,
      _serviceTypeController,
      _emailController,
      _phoneController,
      _notesController,
      _hourlyRateController,
    ]) {
      controller.addListener(_onDirtyFieldChanged);
    }

    _sessionDurationMinutes = existing?.sessionDurationMinutes ?? 60;
    _customDuration = !_presetDurations.contains(_sessionDurationMinutes);
    _customDurationController = TextEditingController(
      text: _customDuration ? _sessionDurationMinutes.toString() : '',
    );
    _sessionFrequency = existing?.sessionFrequency ?? 'Semanal';
    _hasVat = existing?.hasVat ?? false;
    _paymentType = _sessionFrequency == 'Avulso'
        ? PaymentType.avulso
        : (existing?.paymentType ?? PaymentType.mensal);
    _rateType =
        existing?.rateType ??
        (labels.flatRate ? RateType.total : RateType.perHour);

    if (existing != null && existing.sessionFrequency == 'Avulso') {
      final slot = existing.slots.isNotEmpty ? existing.slots.first : null;
      _avulsoDateTime = slot != null
          ? combineDateAndTime(existing.startDate, slot.time)
          : DateTime(now.year, now.month, now.day, now.hour, 0);
      _startDate = dateOnly(_avulsoDateTime);
      _selectedWeekdays = [];
      _slotTimes = {};
    } else if (existing != null) {
      _startDate = dateOnly(existing.startDate);
      _endDate = existing.endDate != null ? dateOnly(existing.endDate!) : null;
      _noEndDate = _endDate == null;
      _selectedWeekdays = existing.slots.map((s) => s.weekday).toList();
      _slotTimes = {for (final s in existing.slots) s.weekday: s.time};
      _avulsoDateTime = combineDateAndTime(
        _startDate,
        const TimeOfDay(hour: 18, minute: 0),
      );
    } else {
      _avulsoDateTime = DateTime(now.year, now.month, now.day, now.hour, 0);
      _startDate = dateOnly(now);
      _selectedWeekdays = [now.weekday];
      _slotTimes = {now.weekday: const TimeOfDay(hour: 18, minute: 0)};
    }
  }

  void _onDirtyFieldChanged() {
    if (mounted) setState(() {});
  }

  /// Verifica se há alterações por guardar, para o PopScope avisar antes de
  /// descartar o formulário (novo cliente: algum campo de texto preenchido;
  /// edição: algum campo já difere do cliente original).
  bool _hasUnsavedChanges() {
    final existing = widget.existingClient;
    if (existing == null) {
      return _nameController.text.trim().isNotEmpty ||
          _serviceTypeController.text.trim().isNotEmpty ||
          _emailController.text.trim().isNotEmpty ||
          _phoneController.text.trim().isNotEmpty ||
          _notesController.text.trim().isNotEmpty ||
          _hourlyRateController.text.trim().isNotEmpty;
    }
    return _nameController.text != existing.name ||
        _serviceTypeController.text != existing.serviceType ||
        _emailController.text != existing.contactEmail ||
        _phoneController.text != existing.contactPhone ||
        _notesController.text != existing.notes ||
        _hourlyRateController.text != existing.hourlyRate.toStringAsFixed(2);
  }

  /// true só durante o instante de um pop disparado pelos próprios botões da
  /// app (Cancelar/Guardar/Descartar) — o PopScope do ecrã bloqueia sempre o
  /// gesto/botão de recuar do sistema, mas estes continuam a funcionar
  /// normalmente porque autorizam o pop momentaneamente antes de o pedir.
  bool _allowSystemPop = false;

  void _popFromAppButton([Client? result]) {
    _allowSystemPop = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _confirmDiscardAndPop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.discardChangesTitle),
        content: Text(s.discardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(s.discard),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _popFromAppButton();
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _serviceTypeController,
      _emailController,
      _phoneController,
      _notesController,
      _hourlyRateController,
    ]) {
      controller.removeListener(_onDirtyFieldChanged);
    }
    _nameController.dispose();
    _serviceTypeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _hourlyRateController.dispose();
    _customDurationController.dispose();
    _customDurationFocus.dispose();
    super.dispose();
  }

  bool get _isAvulso => _sessionFrequency == 'Avulso';

  void _onFrequencyChanged(String value) {
    setState(() {
      _sessionFrequency = value;
      if (_isAvulso) {
        _selectedWeekdays = [];
        _slotTimes = {};
        // Uma sessão Avulsa só faz sentido com pagamento Avulso — não há
        // ciclo semanal/mensal para acumular.
        _paymentType = PaymentType.avulso;
        return;
      }
      if (_paymentType == PaymentType.avulso) {
        _paymentType = PaymentType.mensal;
      }
      final required = requiredWeekdayCount(_sessionFrequency);
      _resyncWeekdaysToRequiredCount(required);
    });
  }

  void _resyncWeekdaysToRequiredCount(int required) {
    if (_selectedWeekdays.isEmpty) {
      _selectedWeekdays = [_startDate.weekday];
      _slotTimes = {_startDate.weekday: const TimeOfDay(hour: 18, minute: 0)};
    }
    while (_selectedWeekdays.length > required) {
      final removed = _selectedWeekdays.removeLast();
      _slotTimes.remove(removed);
    }
    while (_selectedWeekdays.length < required) {
      for (int day = 1; day <= 7; day++) {
        if (!_selectedWeekdays.contains(day)) {
          _selectedWeekdays.add(day);
          _slotTimes[day] = const TimeOfDay(hour: 18, minute: 0);
          break;
        }
      }
    }
    _alignDatesToWeekdays();
  }

  /// Mantém a Data de Início/Fim sempre coerentes com os dias da semana
  /// escolhidos, avançando para a próxima data compatível quando necessário.
  void _alignDatesToWeekdays() {
    if (_isAvulso || _selectedWeekdays.isEmpty) return;
    _startDate = nearestMatchingDate(_startDate, _selectedWeekdays);
    if (_endDate != null) {
      _endDate = nearestMatchingDate(_endDate!, _selectedWeekdays);
    }
  }

  /// Ao atingir o número máximo de dias permitido, substitui o dia mais antigo
  /// selecionado pelo novo, em vez de ignorar o toque (era o bug original:
  /// para frequências que exigem exatamente 1 dia, o seletor ficava bloqueado).
  void _toggleWeekday(int weekday) {
    final required = requiredWeekdayCount(_sessionFrequency);
    setState(() {
      if (_selectedWeekdays.contains(weekday)) {
        if (_selectedWeekdays.length > 1) {
          _selectedWeekdays.remove(weekday);
          _slotTimes.remove(weekday);
        }
        _alignDatesToWeekdays();
        return;
      }
      if (_selectedWeekdays.length < required) {
        _selectedWeekdays.add(weekday);
      } else if (required > 0) {
        final oldest = _selectedWeekdays.removeAt(0);
        _slotTimes.remove(oldest);
        _selectedWeekdays.add(weekday);
      }
      _slotTimes[weekday] = const TimeOfDay(hour: 18, minute: 0);
      _alignDatesToWeekdays();
    });
  }

  List<int> get _sortedWeekdays => [..._selectedWeekdays]..sort();

  Future<void> _pickSlotTime(int weekday) async {
    final current = _slotTimes[weekday] ?? const TimeOfDay(hour: 18, minute: 0);
    final picked = await pickTimeWheel(context, current, s);
    if (picked == null) return;
    setState(() {
      _slotTimes[weekday] = picked;
    });
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5),
      selectableDayPredicate: _selectedWeekdays.isEmpty
          ? null
          : (date) => _selectedWeekdays.contains(date.weekday),
    );
    if (picked == null) return;
    setState(() {
      _startDate = dateOnly(picked);
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(DateTime.now().year + 5),
      selectableDayPredicate: _selectedWeekdays.isEmpty
          ? null
          : (date) => _selectedWeekdays.contains(date.weekday),
    );
    if (picked == null) return;
    setState(() {
      _endDate = dateOnly(picked);
    });
  }

  Future<void> _pickAvulsoDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _avulsoDateTime,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await pickTimeWheel(
      context,
      TimeOfDay.fromDateTime(_avulsoDateTime),
      s,
    );
    if (pickedTime == null) return;

    setState(() {
      _avulsoDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      _startDate = dateOnly(_avulsoDateTime);
    });
  }

  void _selectDurationPreset(int value) {
    setState(() {
      if (value == _customDurationSentinel) {
        _customDuration = true;
        final parsed = int.tryParse(_customDurationController.text);
        if (parsed != null && parsed > 0) _sessionDurationMinutes = parsed;
      } else {
        _customDuration = false;
        _sessionDurationMinutes = value;
      }
    });
    if (value == _customDurationSentinel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _customDurationFocus.requestFocus();
      });
    }
  }

  void _updateCustomDuration(String text) {
    final parsed = int.tryParse(text);
    if (parsed != null && parsed > 0) {
      setState(() => _sessionDurationMinutes = parsed);
    }
  }

  String? _validateCustomDuration(String? value) {
    if (!_customDuration) return null;
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed <= 0) return s.invalidValue;
    return null;
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return s.requiredField;
    final nameRegex = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ0-9\s.\-]+$');
    if (!nameRegex.hasMatch(text)) return s.invalidCharacters;
    return null;
  }

  String? _validateServiceType(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return s.requiredField;
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _phoneController.text.trim().isEmpty ? s.atLeastOneContact : null;
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return s.invalidEmail;
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return _emailController.text.trim().isEmpty ? s.atLeastOneContact : null;
    }
    if (!RegExp(r'^\+?\d+$').hasMatch(text)) return s.numbersOnly;
    return null;
  }

  String? _validateRate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return s.requiredField;
    final number = double.tryParse(text.replaceAll(',', '.'));
    if (number == null || number <= 0) return s.invalidValue;
    return null;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _weekdayMismatchMessage(WeekdayMismatch mismatch) {
    final allowed = mismatch.allowedWeekdays.map(s.weekdayFull).join(', ');
    return s.weekdayMismatch(
      _formatDate(_startDate),
      s.weekdayFull(mismatch.actualWeekday),
      allowed,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    List<WeeklySlot> slots;
    DateTime startDate;
    DateTime? endDate;

    if (_isAvulso) {
      slots = [
        WeeklySlot(
          weekday: _avulsoDateTime.weekday,
          time: TimeOfDay.fromDateTime(_avulsoDateTime),
        ),
      ];
      startDate = dateOnly(_avulsoDateTime);
      endDate = null;
    } else {
      final required = requiredWeekdayCount(_sessionFrequency);
      if (_selectedWeekdays.length != required) {
        showAppSnackBar(SnackBar(content: Text(s.selectExactlyDays(required))));
        return;
      }

      slots = _sortedWeekdays
          .map((wd) => WeeklySlot(weekday: wd, time: _slotTimes[wd]!))
          .toList();
      startDate = _startDate;
      endDate = _noEndDate ? null : _endDate;

      final startMismatch = validateDateMatchesWeekdays(startDate, slots);
      if (startMismatch != null) {
        showAppSnackBar(
          SnackBar(
            content: Text(
              s.startDateError(_weekdayMismatchMessage(startMismatch)),
            ),
          ),
        );
        return;
      }
      if (endDate == null && !_noEndDate) {
        showAppSnackBar(SnackBar(content: Text(s.indicateEndDate)));
        return;
      }
      if (endDate != null) {
        final endMismatch = validateDateMatchesWeekdays(endDate, slots);
        if (endMismatch != null) {
          showAppSnackBar(
            SnackBar(
              content: Text(
                s.endDateError(_weekdayMismatchMessage(endMismatch)),
              ),
            ),
          );
          return;
        }
      }
    }

    final rate = double.parse(
      _hourlyRateController.text.trim().replaceAll(',', '.'),
    );

    final client = Client(
      id:
          widget.existingClient?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _capitalizeFirstLetter(_nameController.text.trim()),
      serviceType: _capitalizeFirstLetter(_serviceTypeController.text.trim()),
      contactEmail: _emailController.text.trim(),
      contactPhone: _phoneController.text.trim(),
      notes: _capitalizeFirstLetter(_notesController.text.trim()),
      sessionDurationMinutes: _sessionDurationMinutes,
      sessionFrequency: _sessionFrequency,
      slots: slots,
      startDate: startDate,
      endDate: endDate,
      hourlyRate: rate,
      rateType: _rateType,
      hasVat: _hasVat,
      paymentType: _paymentType,
      activityType: _clientActivityType,
      // Preserva as exceções pontuais de horário (ver OccurrenceOverride) ao
      // editar — este construtor faz sempre um Client novo, nunca copyWith.
      occurrenceOverrides: widget.existingClient?.occurrenceOverrides ?? const [],
    );

    _popFromAppButton(client);
  }

  @override
  Widget build(BuildContext context) {
    final singularLower = labels.clientSingular.toLowerCase();
    final sessionLower = labels.sessionSingular.toLowerCase();
    final required = requiredWeekdayCount(_sessionFrequency);

    return PopScope(
      // Nunca sair por gesto/botão de recuar do sistema — a navegação neste
      // ecrã é sempre através dos botões da própria app ("Cancelar"/
      // "Guardar"), nunca por ação do sistema operativo. _allowSystemPop só
      // fica true no instante de um pop pedido por esses botões (ver
      // _popFromAppButton), por isso o gesto do sistema continua bloqueado.
      canPop: _allowSystemPop,
      onPopInvokedWithResult: (didPop, result) {
        _allowSystemPop = false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          surfaceTintColor: AppColors.surface,
          leading: TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            onPressed: () => _hasUnsavedChanges()
                ? _confirmDiscardAndPop()
                : _popFromAppButton(),
            child: Text(
              s.cancel,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          leadingWidth: 110,
          title: Text(
            _isEditing
                ? s.editNoun(shortCompoundLabel(labels.clientSingular))
                : s.newLabel(shortCompoundLabel(labels.clientSingular)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              child: Text(
                s.save,
                style: const TextStyle(
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
                  FormSectionTitle(title: s.activityTypeTitle),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: DropdownButtonFormField<ActivityType>(
                      key: ValueKey(
                        'clientActivityType-${_clientActivityType.name}',
                      ),
                      initialValue: _clientActivityType,
                      decoration: schedifyInputDecoration(s.activityTypeTitle),
                      items: ActivityType.values.map((type) {
                        final typeLabels = getLabels(type, widget.language);
                        final color = colorForActivityType(type);
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                iconForActivityType(type),
                                color: color,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(typeLabels.areaName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _clientActivityType = value);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  FormSectionTitle(title: s.infoSection(singularLower)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        SchedifyTextField(
                          controller: _nameController,
                          label: s.nameLabel,
                          validator: _validateName,
                        ),
                        const SizedBox(height: 14),
                        SchedifyTextField(
                          controller: _serviceTypeController,
                          label: labels.serviceTypeLabel,
                          validator: _validateServiceType,
                        ),
                        const SizedBox(height: 14),
                        SchedifyTextField(
                          controller: _emailController,
                          label: s.emailLabel,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                        ),
                        const SizedBox(height: 14),
                        SchedifyTextField(
                          controller: _phoneController,
                          label: s.phoneLabel,
                          helperText: s.phoneHint,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SchedifyTextField(
                          controller: _notesController,
                          label: s.notesLabel,
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FormSectionTitle(
                    title: s.sessionConfigSection(
                      sessionLower,
                      masculine: labels.sessionIsMasculine,
                    ),
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
                          key: ValueKey(
                            'duration-${_customDuration ? _customDurationSentinel : _sessionDurationMinutes}',
                          ),
                          initialValue: _customDuration
                              ? _customDurationSentinel
                              : _sessionDurationMinutes,
                          decoration: schedifyInputDecoration(
                            labels.durationLabel,
                          ),
                          items: [
                            ..._presetDurations.map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(s.minutesOption(m)),
                              ),
                            ),
                            DropdownMenuItem(
                              value: _customDurationSentinel,
                              child: Text(s.customDurationOption),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) _selectDurationPreset(value);
                          },
                        ),
                        if (_customDuration) ...[
                          const SizedBox(height: 14),
                          SchedifyTextField(
                            controller: _customDurationController,
                            focusNode: _customDurationFocus,
                            label: s.customDurationFieldLabel,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: _validateCustomDuration,
                            onChanged: _updateCustomDuration,
                          ),
                        ],
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          key: ValueKey('sessionFrequency-$_sessionFrequency'),
                          initialValue: _sessionFrequency,
                          decoration: schedifyInputDecoration(
                            labels.frequencyLabel,
                          ),
                          items: kSessionFrequencyKeys
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(
                                    sessionFrequencyLabel(f, widget.language),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) _onFrequencyChanged(value);
                          },
                        ),
                        if (!_isAvulso) ...[
                          const SizedBox(height: 14),
                          WeekdaySelector(
                            selectedWeekdays: _selectedWeekdays,
                            maxSelection: required,
                            onToggle: _toggleWeekday,
                            weekdaysLabel: s.weekdaysCount(required),
                            weekdayShortLabels: List.generate(
                              7,
                              (i) => s.weekdayShort(i + 1),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ..._sortedWeekdays.map((wd) {
                            final time =
                                _slotTimes[wd] ??
                                const TimeOfDay(hour: 18, minute: 0);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _pickSlotTime(wd),
                                child: InputDecorator(
                                  decoration: schedifyInputDecoration(
                                    s.hourFor(s.weekdayShort(wd)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          time.format(context),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: AppColors.neutralDark,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: AppColors.neutralSoft,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          DateTimePickerField(
                            label: s.startDateLabel,
                            value: _startDate,
                            showTime: false,
                            onTap: _pickStartDate,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  s.noEndDateLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.neutralMedium,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _noEndDate,
                                onChanged: (value) =>
                                    setState(() => _noEndDate = value),
                                activeThumbColor: AppColors.brandBlue,
                              ),
                            ],
                          ),
                          if (!_noEndDate) ...[
                            const SizedBox(height: 14),
                            DateTimePickerField(
                              label: s.endDateLabel,
                              value: _endDate ?? _startDate,
                              showTime: false,
                              onTap: _pickEndDate,
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 14),
                          DateTimePickerField(
                            label: s.dateTimeLabel,
                            value: _avulsoDateTime,
                            onTap: _pickAvulsoDateTime,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  FormSectionTitle(title: s.paymentConfigSection),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SchedifyTextField(
                                controller: _hourlyRateController,
                                label: _rateType == RateType.total
                                    ? s.rateLabelTotal
                                    : s.rateLabelPerHour,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _validateRate,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: SegmentedButton<RateType>(
                                segments: [
                                  ButtonSegment(
                                    value: RateType.perHour,
                                    label: Text(s.perHourOption),
                                  ),
                                  ButtonSegment(
                                    value: RateType.total,
                                    label: Text(s.totalOption),
                                  ),
                                ],
                                selected: {_rateType},
                                showSelectedIcon: false,
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onSelectionChanged: (selection) =>
                                    setState(() => _rateType = selection.first),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<PaymentType>(
                          key: ValueKey('paymentType-${_paymentType.name}'),
                          initialValue: _paymentType,
                          decoration: schedifyInputDecoration(
                            s.paymentFrequencyLabel,
                          ),
                          items: PaymentType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    paymentTypeLabel(t, widget.language),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _isAvulso
                              ? null
                              : (value) {
                                  if (value != null)
                                    setState(() => _paymentType = value);
                                },
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _hasVat,
                          onChanged: (value) => setState(() => _hasVat = value),
                          title: Text(s.vatSwitchLabel),
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
                      s.scheduleHint(
                        labels.sessionPlural.toLowerCase(),
                        masculine: labels.sessionIsMasculine,
                      ),
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
      ),
    );
  }
}
