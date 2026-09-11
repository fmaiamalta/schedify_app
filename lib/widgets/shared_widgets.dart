import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../i18n/app_strings.dart';
import '../theme.dart';

/// Seletor de hora com scroll (horas e minutos em rodas), em vez do relógio
/// analógico do Material [showTimePicker].
Future<TimeOfDay?> pickTimeWheel(BuildContext context, TimeOfDay initial, AppStrings s) async {
  final now = DateTime.now();
  var picked = DateTime(now.year, now.month, now.day, initial.hour, initial.minute);

  final result = await showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(TimeOfDay(hour: picked.hour, minute: picked.minute)),
                  child: Text(s.done, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            SizedBox(
              height: 220,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: picked,
                onDateTimeChanged: (value) => picked = value,
              ),
            ),
          ],
        ),
      );
    },
  );

  return result;
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SizedBox(
        height: 100,
        child: Image.asset(
          'assets/images/schedify_logo_horizontal.png',
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

/// Linha do título grande de cada ecrã, com o botão de definições (engrenagem)
/// alinhado à direita, à mesma altura do título — igual em todos os ecrãs.
class ScreenTitleRow extends StatelessWidget {
  final String title;
  final VoidCallback onOpenSettings;
  final String settingsTooltip;

  const ScreenTitleRow({super.key, required this.title, required this.onOpenSettings, required this.settingsTooltip});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.neutralDark, height: 1.1),
          ),
        ),
        IconButton(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_outlined),
          color: AppColors.neutralMedium,
          tooltip: settingsTooltip,
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.neutralDark,
        height: 1.15,
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color textColor;
  final Color background;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.textColor,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: iconColor),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final Color background;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.valueColor,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutralSoft,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: valueColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const InfoTile({super.key, required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandBlue, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.neutralDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.neutralSoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ClientCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final Color? accentColor;
  final String? badgeLabel;

  const ClientCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onTap,
    this.accentColor,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.brandBlue;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.person_outline, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutralDark,
                          ),
                        ),
                      ),
                      if (badgeLabel != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            badgeLabel!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.neutralMedium),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: AppColors.neutralSoft),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.neutralSoft),
          ],
        ),
      ),
    );
  }
}

class FormSectionTitle extends StatelessWidget {
  final String title;

  const FormSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.neutralSoft,
        letterSpacing: 0.5,
      ),
    );
  }
}

class DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const DetailLine({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.neutralMedium,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppColors.neutralSoft, height: 1.4),
          ),
        ),
      ],
    );
  }
}

InputDecoration schedifyInputDecoration(String label, {String? helperText}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.neutralSoft),
    helperText: helperText,
    helperMaxLines: 2,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.brandBlue),
    ),
  );
}

class SchedifyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final Key? fieldKey;
  final String? helperText;
  final TextCapitalization textCapitalization;
  final bool autocorrect;

  const SchedifyTextField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.focusNode,
    this.fieldKey,
    this.helperText,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      style: const TextStyle(fontSize: 16, color: AppColors.neutralDark),
      decoration: schedifyInputDecoration(label, helperText: helperText),
    );
  }
}

class DateTimePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  final bool showTime;

  const DateTimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.showTime = true,
  });

  @override
  Widget build(BuildContext context) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final text = showTime
        ? '$day/$month/$year • ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}'
        : '$day/$month/$year';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: schedifyInputDecoration(label),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 16, color: AppColors.neutralDark)),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.neutralSoft),
          ],
        ),
      ),
    );
  }
}

/// Seletor de dias da semana. Quando se atinge o número máximo de dias
/// permitido pela frequência escolhida, o dia mais antigo selecionado é
/// substituído pelo novo (em vez de simplesmente ignorar o toque).
class WeekdaySelector extends StatelessWidget {
  final List<int> selectedWeekdays;
  final int maxSelection;
  final ValueChanged<int> onToggle;
  final String weekdaysLabel;
  final List<String>? weekdayShortLabels;

  const WeekdaySelector({
    super.key,
    required this.selectedWeekdays,
    required this.maxSelection,
    required this.onToggle,
    this.weekdaysLabel = 'Dias da semana',
    this.weekdayShortLabels,
  });

  @override
  Widget build(BuildContext context) {
    final shorts = weekdayShortLabels ?? const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final weekdayLabels = {for (var i = 0; i < 7; i++) i + 1: shorts[i]};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          weekdaysLabel,
          style: const TextStyle(fontSize: 14, color: AppColors.neutralSoft, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: weekdayLabels.entries.map((entry) {
            final selected = selectedWeekdays.contains(entry.key);
            return FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: (_) => onToggle(entry.key),
              selectedColor: AppColors.brandBlueSoft,
              checkmarkColor: AppColors.brandBlue,
              labelStyle: TextStyle(
                color: selected ? AppColors.brandBlue : AppColors.neutralMedium,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide.none,
              backgroundColor: AppColors.surface,
            );
          }).toList(),
        ),
      ],
    );
  }
}
