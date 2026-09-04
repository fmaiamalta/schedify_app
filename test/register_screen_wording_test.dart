// Regression coverage for a real-device-testing finding: RegisterScreen's
// list can include occurrences from clients across every activity type in
// use (registerableNow is built from ALL clients, not just the current
// workspace's — by design, so the Dashboard gives a global view), but the
// screen's title/subtitle used to hardcode the workspace's own session noun
// (e.g. always "Registar Aula"), which was wrong whenever the list actually
// contained a different activity's item (e.g. a Fitness "Treino"). Fixed:
// the title/subtitle are now generic, and each list item shows the correct
// noun derived from that occurrence's own client.activityType.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/i18n/app_strings.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/screens/register_screen.dart';

Client _client(ActivityType type, String name) {
  return Client(
    id: name,
    activityType: type,
    name: name,
    contactEmail: '',
    contactPhone: '',
    notes: '',
    serviceType: '',
    sessionFrequency: 'Semanal',
    slots: const [WeeklySlot(weekday: 1, time: TimeOfDay(hour: 18, minute: 0))],
    sessionDurationMinutes: 60,
    startDate: DateTime(2026, 1, 5),
    endDate: null,
    paymentType: PaymentType.mensal,
    rateType: RateType.perHour,
    hourlyRate: 20,
    hasVat: false,
  );
}

void main() {
  testWidgets('title is generic and each item shows its own client\'s session noun, '
      'even when the list mixes activity types', (WidgetTester tester) async {
    final educationClient = _client(ActivityType.education, 'Ana');
    final fitnessClient = _client(ActivityType.fitness, 'Bruno');

    await tester.pumpWidget(MaterialApp(
      home: RegisterScreen(
        strings: const AppStrings(AppLanguage.pt),
        sessionsTick: ValueNotifier<int>(0),
        occurrencesProvider: () => [
          PlannedOccurrence(client: educationClient, scheduledFor: DateTime(2026, 1, 5, 18, 0)),
          PlannedOccurrence(client: fitnessClient, scheduledFor: DateTime(2026, 1, 5, 18, 0)),
        ],
        onRegisterOccurrence: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    // Title no longer commits to a single activity's noun.
    expect(find.text('Registar'), findsWidgets);
    expect(find.text('Registar Aula'), findsNothing);

    // Each item names its own client's session type correctly.
    expect(find.textContaining('Aula'), findsOneWidget);
    expect(find.textContaining('Treino'), findsOneWidget);
  });
}
