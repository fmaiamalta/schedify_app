// Regression coverage for a real device-testing finding: on Android,
// pressing hardware BACK from a top-level tab navigated back to the
// onboarding ("Escolha o tipo de atividade") screen instead of exiting the
// app, because choosing an activity type used Navigator.push (stacking
// HomeShell on top of onboarding) instead of pushReplacement. Data itself
// was never lost -- this was a pure navigation-stack bug.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('choosing an activity type on first launch replaces the onboarding route '
      'instead of stacking on top of it, so back from HomeShell exits the app', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SchedifyApp());
    await tester.pumpAndSettle();

    expect(find.text('Escolha o tipo de atividade'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Joana Silva');
    await tester.tap(find.text('Educação'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha o tipo de atividade'), findsNothing);

    // Simulate the Android hardware back button from a top-level tab.
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    final handledInApp = await widgetsAppState.didPopRoute() as bool;
    await tester.pumpAndSettle();

    expect(handledInApp, isFalse,
        reason: 'Fixed: there must be no more routes to pop internally (onboarding was '
            'replaced, not stacked under HomeShell), so the app correctly exits instead of '
            'resurfacing onboarding.');
    expect(find.text('Escolha o tipo de atividade'), findsNothing);
  });
}
