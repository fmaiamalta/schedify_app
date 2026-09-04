// Shared iOS/Android end-to-end flow, driven through Flutter's own
// integration_test framework (WidgetTester) so the exact same script runs
// unmodified on both platforms — any behavioral difference found this way is
// a genuine platform inconsistency, not an artifact of two different testing
// methodologies (see the previous AppleScript-based pass, which could only
// verify app launch on iOS due to missing macOS Accessibility permissions).
//
// Run with, e.g.:
//   flutter test integration_test/app_flow_test.dart -d <ios-udid>
//   flutter test integration_test/app_flow_test.dart -d <android-device-id>
//
// IMPORTANT tree-shape note: HomeShell shows its four tabs inside an
// IndexedStack, and MaterialPageRoute defaults to maintainState:true — so
// EVERY tab (and every previously-pushed route) stays mounted in the widget
// tree the whole time, just unpainted. Several strings/icons this app uses
// (the settings gear, "Nesta atividade"/"Todos", "Novo Aluno/Formando") are
// therefore NOT globally unique once more than one tab can show them — every
// finder below is deliberately scoped with find.descendant(of: ...) to the
// specific tab/icon that's actually on screen, rather than assuming
// find.text(...) resolves to a single widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:schedify_app/main.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/screens/clients_tab.dart';
import 'package:schedify_app/screens/dashboard_tab.dart';
import 'package:schedify_app/screens/payments_tab.dart';
import 'package:schedify_app/screens/subjects_tab.dart';

Future<void> _checkpoint(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  debugPrint('E2E_CHECKPOINT: $name');
  await Future<void>.delayed(const Duration(seconds: 3));
  await tester.pump();
}

/// Scrolls the nearest Scrollable so [finder] is on screen before
/// tapping/entering text into it — on a real phone-sized screen the
/// add-client form is taller than the viewport, and WidgetTester.tap
/// computes a hit-test at the widget's actual geometry, so an off-screen
/// widget must be scrolled into view first (unlike a widget test running on
/// a synthetic oversized surface).
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Schedify shared cross-platform flow', (WidgetTester tester) async {
    // ---------------------------------------------------------------
    // 1. Onboarding
    // ---------------------------------------------------------------
    await tester.pumpWidget(const SchedifyApp());
    await _checkpoint(tester, '01_onboarding');

    expect(find.text('Escolha o tipo de atividade'), findsOneWidget,
        reason: 'Onboarding must show on a fresh install with no persisted clients.');

    await tester.tap(find.text('Educação'));
    await _checkpoint(tester, '02_dashboard_after_onboarding');

    expect(find.text('Escolha o tipo de atividade'), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);

    // ---------------------------------------------------------------
    // 2. Add first client (Education, weekly Monday 18:00, Mensal, rate 20)
    //    — opened from Dashboard's "Novo Aluno/Formando" quick action, which
    //    has a unique icon (person_add_alt_1_outlined) even though the same
    //    LABEL TEXT also exists right now on the still-mounted (offstage)
    //    empty-state ClientsTab button underneath.
    // ---------------------------------------------------------------
    await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Novo Aluno/Formando'), findsWidgets, reason: 'Add-client form title.');

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Testadora'); // Nome
    await tester.enterText(find.byType(TextFormField).at(1), 'Matemática'); // Disciplina
    await tester.enterText(find.byType(TextFormField).at(2), 'ana@example.com'); // Email
    await tester.pumpAndSettle();

    // Force the weekly slot onto Monday specifically (default is "today").
    final segChip = find.widgetWithText(FilterChip, 'Seg');
    await _reveal(tester, segChip);
    await tester.tap(segChip);
    await tester.pumpAndSettle();

    // Payment frequency defaults to "Mensal" already for a non-Avulso client
    // — verify rather than blindly re-select, so a regression there would
    // surface as a failed assertion instead of being silently masked.
    expect(find.text('Mensal'), findsOneWidget);

    final rateField = find.byType(TextFormField).at(5);
    await _reveal(tester, rateField);
    await tester.enterText(rateField, '20');
    await tester.pumpAndSettle();

    await _checkpoint(tester, '03_first_client_filled');

    await tester.tap(find.text('Guardar'));
    await _checkpoint(tester, '04_first_client_saved');

    // ---------------------------------------------------------------
    // Verify client appears in Clients list
    // ---------------------------------------------------------------
    await tester.tap(find.byIcon(Icons.people_outline));
    await _checkpoint(tester, '05_clients_tab_one_client');

    expect(find.text('Ana Testadora'), findsOneWidget);
    // Only one activity type exists so far -> the "Nesta atividade/Todos"
    // toggle must NOT be visible anywhere yet.
    expect(find.text('Todos'), findsNothing);

    // ---------------------------------------------------------------
    // 3. Add second client under Fitness via the per-client activityType
    //    dropdown inside the add-client form (the UI exposes this — no need
    //    to go through Settings' workspace switcher). Opened via the "+"
    //    button that's now part of ClientsTab's non-empty-state header.
    // ---------------------------------------------------------------
    final clientsAddButton = find.descendant(of: find.byType(ClientsTab), matching: find.byIcon(Icons.add));
    await tester.tap(clientsAddButton);
    await tester.pumpAndSettle();

    final activityDropdown = find.byType(DropdownButtonFormField<ActivityType>);
    await _reveal(tester, activityDropdown);
    await tester.tap(activityDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fitness').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Bruno Fit');
    await tester.enterText(find.byType(TextFormField).at(1), 'Musculação');
    await tester.enterText(find.byType(TextFormField).at(2), 'bruno@example.com');
    await tester.pumpAndSettle();

    final rateField2 = find.byType(TextFormField).at(5);
    await _reveal(tester, rateField2);
    await tester.enterText(rateField2, '25');
    await tester.pumpAndSettle();

    await _checkpoint(tester, '06_second_client_filled');

    await tester.tap(find.text('Guardar'));
    await _checkpoint(tester, '07_second_client_saved');

    // ---------------------------------------------------------------
    // Verify the "Nesta atividade / Todos" toggle now appears (scoped to
    // ClientsTab: Subjects and Payments also satisfy the same condition and
    // would each contribute their own matching Text widgets, since all tabs
    // stay mounted under the IndexedStack) and switches the displayed list +
    // header label correctly both ways.
    // ---------------------------------------------------------------
    Finder inClients(Finder f) => find.descendant(of: find.byType(ClientsTab), matching: f);

    expect(inClients(find.text('Nesta atividade')), findsOneWidget);
    expect(inClients(find.text('Todos')), findsOneWidget);
    // Default state: "Nesta atividade" (Education only) -> only Ana visible.
    expect(find.text('Ana Testadora'), findsOneWidget);
    expect(find.text('Bruno Fit'), findsNothing);
    expect(inClients(find.text('Alunos/Formandos')), findsOneWidget); // Education header label

    await tester.tap(inClients(find.text('Todos')));
    await _checkpoint(tester, '08_clients_toggle_all');

    expect(inClients(find.text('Todos os Inscritos')), findsOneWidget, reason: 'Header label switches to the "all" title.');
    expect(find.text('Ana Testadora'), findsOneWidget);
    expect(find.text('Bruno Fit'), findsOneWidget);

    await tester.tap(inClients(find.text('Nesta atividade')));
    await tester.pumpAndSettle();
    expect(inClients(find.text('Alunos/Formandos')), findsOneWidget, reason: 'Header label reverts.');
    expect(find.text('Bruno Fit'), findsNothing);

    // Same toggle, same behavior expected on Subjects.
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await _checkpoint(tester, '09_subjects_tab');
    Finder inSubjects(Finder f) => find.descendant(of: find.byType(SubjectsTab), matching: f);
    expect(inSubjects(find.text('Nesta atividade')), findsOneWidget);
    expect(inSubjects(find.text('Todos')), findsOneWidget);

    // ---------------------------------------------------------------
    // 4. Register today's/this-week's occurrence for the first client, IF
    //    the Dashboard's registerable list is non-empty. Ana's slot is a
    //    future Monday (the weekly-slot save logic snaps the start date
    //    forward to the next matching weekday), so we expect this to be
    //    empty whenever this suite is run on a non-Monday — assert on
    //    whichever branch is actually true rather than forcing one.
    // ---------------------------------------------------------------
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pumpAndSettle();

    final registerCard = find.descendant(of: find.byType(DashboardTab), matching: find.byIcon(Icons.check_circle_outline));
    await tester.tap(registerCard);
    await _checkpoint(tester, '10_register_screen');

    final nothingToRegister = find.text('Nada por registar.');
    final registerButtons = find.text('Registar');
    var registeredSomething = false;
    if (tester.any(nothingToRegister)) {
      debugPrint('E2E_NOTE: registerableNow was empty — nothing to register today, not forcing one.');
      expect(nothingToRegister, findsOneWidget);
    } else {
      // Bruno's (Fitness) weekly slot defaults to *today's* weekday (we only
      // forced Ana's slot to Monday) — on a run where today happens to be
      // Bruno's day, this list is non-empty. Register it, as instructed.
      debugPrint('E2E_NOTE: registerableNow had at least one entry — registering the first one.');
      await tester.tap(registerButtons.first);
      await tester.pumpAndSettle();
      registeredSomething = true;
    }

    // Back to Dashboard. Use the BackButton widget type directly rather than
    // WidgetTester.pageBack(), which looks for the English "Back" tooltip
    // (or a CupertinoNavigationBarBackButton) and fails once the app's
    // locale is Portuguese — Material's own back button tooltip is "Voltar"
    // there, so pageBack() finds neither and throws. This is purely a test
    // helper mismatch, not an app bug, but worth documenting: any future
    // integration test in this app that reaches for pageBack() will hit the
    // same wall as soon as the app isn't in English.
    await tester.tap(find.byType(BackButton));
    await _checkpoint(tester, '11_back_to_dashboard');

    // ---------------------------------------------------------------
    // 5. Payments tab: Pending/Completed sub-tabs render without error.
    // ---------------------------------------------------------------
    await tester.tap(find.byIcon(Icons.payments_outlined));
    await _checkpoint(tester, '12_payments_pending');

    expect(find.text('Pendentes'), findsOneWidget);
    expect(find.text('Efetuados'), findsOneWidget);

    // PaymentsTab defaults to "Nesta atividade" (Education-only) scope. If
    // the occurrence registered above belonged to Bruno (Fitness), it will
    // NOT show up here yet even though it now exists — that's correct,
    // scoped behavior, not a bug. Switch to "Todos" for a scope-independent
    // check of whether the registration actually landed, regardless of
    // which of the two clients' occurrence happened to be due today.
    final paymentsToggleAll = find.descendant(of: find.byType(PaymentsTab), matching: find.text('Todos'));
    if (tester.any(paymentsToggleAll)) {
      await tester.tap(paymentsToggleAll);
      await tester.pumpAndSettle();
    }

    if (registeredSomething) {
      debugPrint('E2E_NOTE: a session was registered above — under "Todos" its client\'s '
          'cycle must show as pending instead of the empty state.');
      expect(find.text('Sem pagamentos pendentes.'), findsNothing);
    } else {
      expect(find.text('Sem pagamentos pendentes.'), findsWidgets);
    }

    await tester.tap(find.text('Efetuados'));
    await _checkpoint(tester, '13_payments_completed');
    // Nothing was ever marked paid in this script, regardless of the branch
    // above, so Completed must always be empty.
    expect(find.text('Ainda não há pagamentos efetuados.'), findsWidgets);

    // ---------------------------------------------------------------
    // 6. Settings: toggle language to English, verify strings change, then
    //    revert to Portuguese and verify it reverts. The settings gear icon
    //    is scoped to DashboardTab because every tab renders its own
    //    (offstage) copy of it.
    // ---------------------------------------------------------------
    await tester.tap(find.byIcon(Icons.dashboard_outlined));
    await tester.pumpAndSettle();

    Finder dashboardSettingsGear() =>
        find.descendant(of: find.byType(DashboardTab), matching: find.byIcon(Icons.settings_outlined));

    await tester.tap(dashboardSettingsGear());
    await _checkpoint(tester, '14_settings_pt');
    expect(find.text('Definições'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await _checkpoint(tester, '15_after_switch_to_english');

    expect(find.text('Home'), findsOneWidget, reason: 'Bottom nav label must be translated.');
    expect(find.text('Início'), findsNothing);

    await tester.tap(dashboardSettingsGear());
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget, reason: 'Settings screen title itself must be translated.');

    await tester.tap(find.text('Português'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await _checkpoint(tester, '16_reverted_to_portuguese');

    expect(find.text('Início'), findsOneWidget, reason: 'Language must revert fully.');
    expect(find.text('Home'), findsNothing);

    // ---------------------------------------------------------------
    // 7. Discard-confirmation dialog on an unsaved add-client form, using a
    //    simulated system back-route pop (`WidgetsApp.didPopRoute`) — the
    //    same technique the existing add_client_discard_confirmation_test
    //    widget test uses, and the most faithful thing a single shared
    //    integration_test script can drive identically on both platforms:
    //    iOS has no hardware back button, and Android's is delivered to
    //    Flutter through this exact same route-pop channel, so this is a
    //    framework-level equivalent of "the user tried to leave" on either
    //    platform, not a literal OS gesture.
    // ---------------------------------------------------------------
    await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Rascunho Não Guardado');
    await tester.pumpAndSettle();
    await _checkpoint(tester, '17_unsaved_draft_before_back');

    dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();
    await _checkpoint(tester, '18_discard_dialog_shown');

    expect(find.text('Descartar alterações?'), findsOneWidget,
        reason: 'This session\'s fix: unsaved text + back must show a discard-confirmation dialog.');

    // Cancel: form must remain, with the text preserved.
    await tester.tap(find.text('Cancelar').last);
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsNothing);
    expect(find.text('Rascunho Não Guardado'), findsOneWidget);

    // Now actually discard.
    widgetsAppState = tester.state(find.byType(WidgetsApp));
    await widgetsAppState.didPopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Descartar alterações?'), findsOneWidget);
    await tester.tap(find.text('Descartar'));
    await _checkpoint(tester, '19_after_discard');

    expect(find.text('Descartar alterações?'), findsNothing);
    expect(find.text('Rascunho Não Guardado'), findsNothing);
    expect(find.text('Dashboard'), findsOneWidget, reason: 'Back on the tab that opened the form.');

    debugPrint('E2E_DONE: all steps completed without an uncaught exception.');
  });
}
