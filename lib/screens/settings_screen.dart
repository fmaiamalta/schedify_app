import 'package:flutter/material.dart';
import '../i18n/app_strings.dart';
import '../models.dart';
import '../theme.dart';

class SettingsResult {
  final ActivityType activityType;
  final AppLanguage language;
  const SettingsResult({required this.activityType, required this.language});
}

/// Ecrã de Definições. Devolve um [SettingsResult] via Navigator.pop quando o
/// utilizador fecha o ecrã; `null` se nada mudou.
class SettingsScreen extends StatefulWidget {
  final ActivityType currentActivityType;
  final AppLanguage currentLanguage;

  const SettingsScreen({super.key, required this.currentActivityType, required this.currentLanguage});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ActivityType _selectedActivity;
  late AppLanguage _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedActivity = widget.currentActivityType;
    _selectedLanguage = widget.currentLanguage;
  }

  AppStrings get s => AppStrings(_selectedLanguage);

  void _close() {
    final changed = _selectedActivity != widget.currentActivityType || _selectedLanguage != widget.currentLanguage;
    Navigator.of(context).pop(
      changed ? SettingsResult(activityType: _selectedActivity, language: _selectedLanguage) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        title: Text(s.settingsTitle, style: const TextStyle(color: AppColors.neutralDark, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _close,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              s.activityTypeTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutralSoft, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              s.activityTypeSubtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.neutralSoft),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: ActivityType.values.map((type) {
                  final labels = getLabels(type, _selectedLanguage);
                  final selected = _selectedActivity == type;
                  return RadioListTile<ActivityType>(
                    value: type,
                    groupValue: _selectedActivity,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedActivity = value);
                    },
                    activeColor: colorForActivityType(type),
                    secondary: Icon(iconForActivityType(type), color: colorForActivityType(type)),
                    title: Text(labels.areaName, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              s.languageTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutralSoft, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text(
              s.languageSubtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.neutralSoft),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  RadioListTile<AppLanguage>(
                    value: AppLanguage.pt,
                    groupValue: _selectedLanguage,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedLanguage = value);
                    },
                    activeColor: AppColors.brandBlue,
                    title: Text(s.portuguese, style: TextStyle(fontWeight: _selectedLanguage == AppLanguage.pt ? FontWeight.w700 : FontWeight.w500)),
                  ),
                  RadioListTile<AppLanguage>(
                    value: AppLanguage.en,
                    groupValue: _selectedLanguage,
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedLanguage = value);
                    },
                    activeColor: AppColors.brandBlue,
                    title: Text(s.english, style: TextStyle(fontWeight: _selectedLanguage == AppLanguage.en ? FontWeight.w700 : FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              s.dataSection,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutralSoft, letterSpacing: 0.5),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(20)),
              child: ListTile(
                leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.neutralSoft),
                title: Text(s.backupTitle),
                subtitle: Text(s.backupSubtitle),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.taupeSoft, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    s.premium,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.taupe),
                  ),
                ),
                enabled: false,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              s.about,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutralSoft, letterSpacing: 0.5),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: AppColors.surfaceWhite, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.code, color: AppColors.neutralSoft),
                    title: Text(s.developedBy),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: AppColors.neutralSoft),
                    title: Text(s.version),
                    subtitle: const Text('1.0.0'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
