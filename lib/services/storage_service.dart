import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

/// Estado completo da app, persistido localmente no dispositivo para que os
/// dados sobrevivam a fechar/reabrir a aplicação.
class PersistedState {
  final ActivityType activityType;
  final AppLanguage language;
  final String providerName;
  final List<Client> clients;
  final Map<String, List<SessionRecord>> sessionsByClient;

  const PersistedState({
    required this.activityType,
    required this.language,
    required this.providerName,
    required this.clients,
    required this.sessionsByClient,
  });
}

class StorageService {
  static const _storageKey = 'schedify_data';

  Future<PersistedState?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_storageKey);
      if (content == null || content.trim().isEmpty) return null;

      final json = jsonDecode(content) as Map<String, dynamic>;

      final clients = (json['clients'] as List<dynamic>? ?? [])
          .map((c) => Client.fromJson(c as Map<String, dynamic>))
          .toList();

      final sessionsJson = json['sessionsByClient'] as Map<String, dynamic>? ?? {};
      final sessionsByClient = <String, List<SessionRecord>>{
        for (final entry in sessionsJson.entries)
          entry.key: (entry.value as List<dynamic>).map((s) => SessionRecord.fromJson(s as Map<String, dynamic>)).toList(),
      };

      return PersistedState(
        activityType: ActivityType.values.byName(json['activityType'] as String? ?? 'education'),
        language: AppLanguage.values.byName(json['language'] as String? ?? 'pt'),
        providerName: json['providerName'] as String? ?? '',
        clients: clients,
        sessionsByClient: sessionsByClient,
      );
    } catch (_) {
      // Ficheiro em falta, corrompido ou de uma versão incompatível: começa vazio
      // em vez de rebentar o arranque da app.
      return null;
    }
  }

  Future<void> save({
    required ActivityType activityType,
    required AppLanguage language,
    required String providerName,
    required List<Client> clients,
    required Map<String, List<SessionRecord>> sessionsByClient,
  }) async {
    final json = {
      'activityType': activityType.name,
      'language': language.name,
      'providerName': providerName,
      'clients': clients.map((c) => c.toJson()).toList(),
      'sessionsByClient': {
        for (final entry in sessionsByClient.entries) entry.key: entry.value.map((s) => s.toJson()).toList(),
      },
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(json));
  }
}
