// Regression coverage for a real iOS smoke-test finding: the session-count
// chip on the main Payments list (e.g. "3 workouts") always used the plural
// noun regardless of the actual count, so a single-session cycle showed
// "1 workouts" (PT: "1 treinos") instead of "1 workout"/"1 treino". This is a
// different call site from AppStrings.reportSummary (the Report dialog's
// summary line), which was already fixed earlier — this chip builds its text
// inline in payments_tab.dart rather than through an AppStrings method.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/home_shell.dart';
import 'package:schedify_app/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Payments list session-count chip uses the singular noun for a 1-session cycle',
    (WidgetTester tester) async {
      final today = DateTime.now();
      final client = Client(
        id: 'c1',
        name: 'Cliente Fitness',
        serviceType: 'Personal Training',
        contactEmail: '',
        contactPhone: '912345678',
        notes: '',
        sessionDurationMinutes: 60,
        sessionFrequency: 'Avulso',
        slots: const [],
        startDate: DateTime(today.year, today.month, today.day),
        endDate: null,
        hourlyRate: 30,
        rateType: RateType.total,
        hasVat: false,
        paymentType: PaymentType.avulso,
        activityType: ActivityType.fitness,
      );
      final session = SessionRecord(
        id: 's1',
        clientId: 'c1',
        registeredAt: today,
        scheduledFor: today,
        durationMinutes: 60,
        amount: 30,
      );

      await tester.pumpWidget(MaterialApp(
        home: HomeShell(
          initialActivityType: ActivityType.fitness,
          initialClients: [client],
          initialSessions: {'c1': [session]},
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.payments_outlined));
      await tester.pumpAndSettle();

      expect(find.text('1 treino'), findsOneWidget);
      expect(find.text('1 treinos'), findsNothing);
    },
  );
}
