import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/home_shell.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/screens/payments_tab.dart';
import 'package:schedify_app/screens/subjects_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'HomeShell preserves PaymentsTab\'s State (via IndexedStack) across a bottom-nav '
    'round trip, so local flags like _reportSentKeys and _showAll survive switching '
    'away to another tab and back -- not just app restart.',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HomeShell(initialActivityType: ActivityType.education),
      ));
      await tester.pumpAndSettle();

      // Go to Payments tab (index 3).
      await tester.tap(find.byIcon(Icons.payments_outlined));
      await tester.pumpAndSettle();

      final paymentsStateBefore = tester.state(find.byType(PaymentsTab));

      // Go to Dashboard (index 0) and back to Payments (index 3) -- something a
      // real user does constantly (e.g. to check today's schedule mid-workflow).
      await tester.tap(find.byIcon(Icons.dashboard_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.payments_outlined));
      await tester.pumpAndSettle();

      final paymentsStateAfter = tester.state(find.byType(PaymentsTab));

      expect(
        identical(paymentsStateBefore, paymentsStateAfter),
        isTrue,
        reason: 'Fixed via IndexedStack: PaymentsTab State identity must survive a tab '
            'round trip, so _reportSentKeys is not silently wiped. A user who sends a '
            'payment report, glances at the Dashboard, then comes back to Payments to '
            'mark it paid must not see the "report not sent" warning reappear.',
      );
    },
  );

  testWidgets(
    'SubjectsTab\'s "Nesta atividade / Todos" toggle state survives switching away '
    'and back, thanks to the same IndexedStack fix.',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: HomeShell(initialActivityType: ActivityType.education),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu_book_outlined)); // Subjects tab
      await tester.pumpAndSettle();

      final subjectsStateBefore = tester.state(find.byType(SubjectsTab));

      await tester.tap(find.byIcon(Icons.dashboard_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.menu_book_outlined));
      await tester.pumpAndSettle();

      final subjectsStateAfter = tester.state(find.byType(SubjectsTab));

      expect(identical(subjectsStateBefore, subjectsStateAfter), isTrue,
          reason: 'Fixed: SubjectsTab State (and therefore its _showAll toggle) must be '
              'preserved across a tab revisit instead of being recreated.');
    },
  );
}
