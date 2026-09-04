// Follow-up verification for fix #4 (IndexedStack tab preservation).
//
// test/home_shell_tab_state_test.dart already confirms State identity is
// preserved across tab round trips. This file specifically probes the task's
// open question: "does IndexedStack correctly rebuild offstage children when
// parent state changes, or could an offstage tab show stale labels/data
// until you visit it?" -- by changing the workspace ActivityType/Language in
// Settings and then visiting a tab that was NEVER visited before that
// change (so it could only be showing something if it had been eagerly
// pre-rendered with stale props, or lazily built fresh -- either way this
// confirms whether the propagation genuinely works, since IndexedStack keeps
// all four tab Elements mounted and updates them all on every HomeShell
// rebuild, regardless of which index is currently painted).
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
    'changing the language in Settings propagates immediately to a tab that was '
    'never visited before the change (Clients tab), confirming IndexedStack does '
    'NOT leave offstage children stale',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HomeShell(initialActivityType: ActivityType.education, initialLanguage: AppLanguage.pt),
      ));
      await tester.pumpAndSettle();

      // Still on Dashboard (index 0). Open Settings and switch to English
      // WITHOUT ever having visited the Clients tab yet.
      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Idioma'), findsOneWidget); // Settings screen itself, still pt-PT.
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      // Close Settings (pop) to trigger HomeShell's setState with the new language.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Now visit Clients tab for the very first time.
      await tester.tap(find.byIcon(Icons.people_outline));
      await tester.pumpAndSettle();

      // If offstage children were stale, this could still show Portuguese
      // ("Alunos/Formandos") since Clients was never built while pt-PT was active.
      expect(find.text('Students'), findsWidgets,
          reason: 'Confirms fix #4 holds up: IndexedStack rebuilds every child (including '
              'ones never visited/painted before) whenever HomeShell rebuilds, so the '
              'language change reached the Clients tab immediately, with no staleness.');
      expect(find.text('Alunos/Formandos'), findsNothing);
    },
  );

  testWidgets(
    'changing the workspace ActivityType in Settings propagates immediately to '
    'Subjects and Payments tabs even though only Dashboard has ever been visited',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HomeShell(initialActivityType: ActivityType.education, initialLanguage: AppLanguage.pt),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();

      // Switch workspace activity type to Fitness.
      await tester.tap(find.text('Fitness'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Visit Subjects tab (labelled "Disciplina" for Education, "Modalidade /
      // Serviço" for Fitness) for the first time.
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Modalidade / Serviço'), findsOneWidget,
          reason: 'Subjects tab, never built before the Settings change, must reflect the '
              'new Fitness workspace immediately, not the Education label it would have had '
              'if it had been eagerly built while Education was still active.');
      expect(find.text('Disciplina'), findsNothing);
    },
  );
}
