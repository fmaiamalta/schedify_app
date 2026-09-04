// Regression coverage for two related fixes on AddClientScreen's exit flow:
//
// 1. Originally, pressing the hardware BACK button (Android) with fields
//    filled in silently discarded the form with no confirmation.
// 2. Per explicit product decision, the system back gesture/button was then
//    made a total no-op on this screen: navigation only ever happens via the
//    app's own "Cancelar"/"Guardar" buttons, never via the OS. The discard-
//    confirmation dialog still guards the explicit "Cancelar" button when
//    there's unsaved text.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/screens/add_client_screen.dart';

void main() {
  testWidgets('the system back gesture/button is a total no-op on this screen, '
      'even with unsaved text', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AddClientScreen(activityType: ActivityType.education, language: AppLanguage.pt),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ana Teste');
    await tester.pumpAndSettle();

    // Simulate the Android hardware back button / iOS-equivalent system pop.
    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    // Nothing happens: no dialog, screen stays exactly as it was.
    expect(find.text('Descartar alterações?'), findsNothing);
    expect(find.byType(AddClientScreen), findsOneWidget);
    expect(find.text('Ana Teste'), findsOneWidget);
  });

  testWidgets('the system back gesture is a no-op even with NO unsaved text '
      '(navigation is exclusively via the app\'s own buttons)', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const AddClientScreen(activityType: ActivityType.education, language: AppLanguage.pt),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(AddClientScreen), findsOneWidget, reason: 'system back must not close the screen at all');
  });

  testWidgets('the explicit "Cancelar" button still shows the discard-confirmation '
      'dialog with unsaved text, and actually leaves once confirmed', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AddClientScreen(activityType: ActivityType.education, language: AppLanguage.pt),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Ana Teste');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar').first);
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsOneWidget);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(find.byType(AddClientScreen), findsNothing);
  });

  testWidgets('the explicit "Cancelar" button leaves immediately with no dialog '
      'when there is no unsaved text', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AddClientScreen(activityType: ActivityType.education, language: AppLanguage.pt),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar').first);
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsNothing);
    expect(find.byType(AddClientScreen), findsNothing);
  });
}
