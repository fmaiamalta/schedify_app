import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save/load round-trip preserves every Client and SessionRecord field', () async {
    final storage = StorageService();

    final client = Client(
      id: 'c1',
      name: 'Joana Silva',
      serviceType: 'Yoga',
      contactEmail: 'joana@example.com',
      contactPhone: '912345678',
      notes: 'Prefere aulas de manha',
      sessionDurationMinutes: 45,
      sessionFrequency: '2x por semana',
      slots: const [
        WeeklySlot(weekday: 2, time: TimeOfDay(hour: 8, minute: 30)),
        WeeklySlot(weekday: 4, time: TimeOfDay(hour: 19, minute: 15)),
      ],
      startDate: DateTime(2026, 1, 6),
      endDate: DateTime(2026, 12, 31),
      hourlyRate: 27.5,
      rateType: RateType.perHour,
      hasVat: true,
      paymentType: PaymentType.semanal,
      activityType: ActivityType.fitness,
    );

    final session = SessionRecord(
      id: 's1',
      clientId: 'c1',
      registeredAt: DateTime(2026, 1, 6, 9, 0),
      scheduledFor: DateTime(2026, 1, 6, 8, 30),
      durationMinutes: 45,
      amount: 25.35,
      isPaid: true,
      notes: 'pagou em dinheiro',
    );

    await storage.save(
      activityType: ActivityType.fitness,
      language: AppLanguage.en,
      providerName: 'Joana Silva',
      clients: [client],
      sessionsByClient: {
        'c1': [session],
      },
    );

    final loaded = await storage.load();
    expect(loaded, isNotNull);
    expect(loaded!.activityType, ActivityType.fitness);
    expect(loaded.language, AppLanguage.en);
    expect(loaded.providerName, 'Joana Silva');

    final loadedClient = loaded.clients.single;
    expect(loadedClient.id, client.id);
    expect(loadedClient.name, client.name);
    expect(loadedClient.serviceType, client.serviceType);
    expect(loadedClient.contactEmail, client.contactEmail);
    expect(loadedClient.contactPhone, client.contactPhone);
    expect(loadedClient.notes, client.notes);
    expect(loadedClient.sessionDurationMinutes, client.sessionDurationMinutes);
    expect(loadedClient.sessionFrequency, client.sessionFrequency);
    expect(loadedClient.slots.length, 2);
    expect(loadedClient.slots[0].weekday, 2);
    expect(loadedClient.slots[0].time.hour, 8);
    expect(loadedClient.slots[0].time.minute, 30);
    expect(loadedClient.slots[1].weekday, 4);
    expect(loadedClient.startDate, client.startDate);
    expect(loadedClient.endDate, client.endDate);
    expect(loadedClient.hourlyRate, client.hourlyRate);
    expect(loadedClient.rateType, client.rateType);
    expect(loadedClient.hasVat, client.hasVat);
    expect(loadedClient.paymentType, client.paymentType);
    expect(loadedClient.activityType, client.activityType);

    final loadedSession = loaded.sessionsByClient['c1']!.single;
    expect(loadedSession.id, session.id);
    expect(loadedSession.clientId, session.clientId);
    expect(loadedSession.registeredAt, session.registeredAt);
    expect(loadedSession.scheduledFor, session.scheduledFor);
    expect(loadedSession.durationMinutes, session.durationMinutes);
    expect(loadedSession.amount, session.amount);
    expect(loadedSession.isPaid, session.isPaid);
    expect(loadedSession.notes, session.notes);
  });

  test('save/load round-trip preserves occurrenceOverrides (one cancelled, one moved)', () async {
    final storage = StorageService();

    final client = Client(
      id: 'c1',
      name: 'Bruno Alves',
      serviceType: 'Musculação',
      contactEmail: '',
      contactPhone: '912345678',
      notes: '',
      sessionDurationMinutes: 60,
      sessionFrequency: 'Semanal',
      slots: const [WeeklySlot(weekday: 1, time: TimeOfDay(hour: 18, minute: 0))],
      startDate: DateTime(2026, 1, 5),
      endDate: null,
      hourlyRate: 20,
      rateType: RateType.perHour,
      hasVat: false,
      paymentType: PaymentType.mensal,
      activityType: ActivityType.fitness,
      occurrenceOverrides: [
        OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 19, 18, 0), newDateTime: null),
        OccurrenceOverride(originalScheduledFor: DateTime(2026, 1, 12, 18, 0), newDateTime: DateTime(2026, 1, 14, 20, 0)),
      ],
    );

    await storage.save(
      activityType: ActivityType.fitness,
      language: AppLanguage.pt,
      providerName: 'Bruno Costa',
      clients: [client],
      sessionsByClient: {},
    );
    final loaded = await storage.load();

    final loadedOverrides = loaded!.clients.single.occurrenceOverrides;
    expect(loadedOverrides.length, 2);

    final cancelled = loadedOverrides.firstWhere((o) => o.originalScheduledFor == DateTime(2026, 1, 19, 18, 0));
    expect(cancelled.isCancelled, isTrue);
    expect(cancelled.newDateTime, isNull);

    final moved = loadedOverrides.firstWhere((o) => o.originalScheduledFor == DateTime(2026, 1, 12, 18, 0));
    expect(moved.isCancelled, isFalse);
    expect(moved.newDateTime, DateTime(2026, 1, 14, 20, 0));
  });

  test('a persisted Client JSON blob with no occurrenceOverrides key at all still loads, '
      'with occurrenceOverrides == [] (backward compatibility)', () async {
    SharedPreferences.setMockInitialValues({
      'schedify_data': '{"activityType":"education","language":"pt","clients":[{'
          '"id":"c1","name":"Ana","serviceType":"Matematica","contactEmail":"","contactPhone":"912345678","notes":"",'
          '"sessionDurationMinutes":60,"sessionFrequency":"Semanal","slots":[{"weekday":1,"hour":18,"minute":0}],'
          '"startDate":"2026-01-05T00:00:00.000","endDate":null,"hourlyRate":20.0,"rateType":"perHour","hasVat":false,'
          '"paymentType":"mensal","activityType":"education"'
          '}],"sessionsByClient":{}}',
    });

    final loaded = await StorageService().load();
    expect(loaded, isNotNull);
    expect(loaded!.clients.single.occurrenceOverrides, isEmpty);
  });

  test('load() returns null (instead of throwing) for corrupted JSON', () async {
    SharedPreferences.setMockInitialValues({'schedify_data': '{not valid json!!'});
    final loaded = await StorageService().load();
    expect(loaded, isNull);
  });

  test('load() returns null (instead of throwing) when a client is missing a required '
      'non-nullable field (e.g. an old/foreign data shape without paymentType)', () async {
    SharedPreferences.setMockInitialValues({
      'schedify_data': '{"activityType":"education","language":"pt","clients":[{"id":"c1"}],"sessionsByClient":{}}',
    });
    final loaded = await StorageService().load();
    expect(loaded, isNull);
  });
}
