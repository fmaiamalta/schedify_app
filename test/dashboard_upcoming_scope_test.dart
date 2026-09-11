// Regression coverage for a real iOS smoke-test finding: the Dashboard's
// "Upcoming classes/workouts (this week)" card used the section title's
// activity-specific noun (from the current workspace's ActivityLabels), but
// the underlying occurrence list was built from *all* clients regardless of
// activity type -- so, e.g., while working in the Fitness workspace, an
// Education client's class could show up under a "Upcoming Workouts" title
// with no indication it wasn't actually a workout. Every other tab already
// scoped its list to the current workspace via `_workspaceClients`; the
// Dashboard card alone used the unfiltered `_clients`. Fixed in home_shell.dart
// by passing `_workspaceClients` (not `_clients`) to `upcomingThisWeek`/
// `registerableNow` when building DashboardTab.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/home_shell.dart';
import 'package:schedify_app/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Client _clientWithSessionEveryDay({
  required String id,
  required String name,
  required ActivityType activityType,
}) {
  return Client(
    id: id,
    name: name,
    serviceType: 'X',
    contactEmail: '',
    contactPhone: '912345678',
    notes: '',
    sessionDurationMinutes: 60,
    sessionFrequency: 'Semanal',
    // A slot on every weekday guarantees at least one still-unregistered
    // occurrence "this week" regardless of which real-world day the test
    // suite happens to run on.
    slots: List.generate(7, (i) => WeeklySlot(weekday: i + 1, time: const TimeOfDay(hour: 20, minute: 0))),
    startDate: DateTime(2020, 1, 1),
    endDate: null,
    hourlyRate: 20,
    rateType: RateType.perHour,
    hasVat: false,
    paymentType: PaymentType.mensal,
    activityType: activityType,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Dashboard "Upcoming" card only shows occurrences from the current workspace\'s '
    'activity type, not clients from other activities',
    (WidgetTester tester) async {
      final educationClient = _clientWithSessionEveryDay(
        id: 'edu1',
        name: 'Aluno de Educação',
        activityType: ActivityType.education,
      );
      final fitnessClient = _clientWithSessionEveryDay(
        id: 'fit1',
        name: 'Cliente de Fitness',
        activityType: ActivityType.fitness,
      );

      await tester.pumpWidget(MaterialApp(
        home: HomeShell(
          initialActivityType: ActivityType.education,
          initialClients: [educationClient, fitnessClient],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Aluno de Educação'), findsWidgets);
      expect(
        find.text('Cliente de Fitness'),
        findsNothing,
        reason: 'Fixed: while the workspace is Education, the Fitness client\'s occurrence '
            'must not leak into the "Upcoming Classes" card.',
      );
    },
  );
}
