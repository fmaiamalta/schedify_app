// Regression coverage: two small, reusable widgets in
// lib/widgets/shared_widgets.dart used to hardcode Portuguese text with no
// AppLanguage/AppStrings parameter at all, so they never switched to English
// even though the rest of the app did.
//
//   1. ScreenTitleRow's settings-gear IconButton tooltip is now driven by a
//      required `settingsTooltip` parameter (callers pass s.settingsTitle).
//   2. pickTimeWheel()'s bottom sheet now takes an AppStrings parameter and
//      uses s.cancel/s.done instead of hardcoded 'Cancelar'/'Concluir'.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/i18n/app_strings.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/screens/add_client_screen.dart';
import 'package:schedify_app/widgets/shared_widgets.dart';

void main() {
  testWidgets('ScreenTitleRow settings tooltip follows the given language', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScreenTitleRow(
            title: 'Dashboard',
            onOpenSettings: () {},
            settingsTooltip: AppStrings(AppLanguage.en).settingsTitle,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Definições'), findsNothing);
  });

  testWidgets('pickTimeWheel bottom sheet shows English "Cancel"/"Done" inside an '
      'AddClientScreen configured for English', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AddClientScreen(activityType: ActivityType.education, language: AppLanguage.en),
      ),
    );
    await tester.pumpAndSettle();

    final timeFieldIcon = find.byIcon(Icons.access_time).first;
    final tappable = find.ancestor(of: timeFieldIcon, matching: find.byType(InkWell)).first;
    await tester.ensureVisible(tappable);
    await tester.pumpAndSettle();
    await tester.tap(tappable);
    await tester.pumpAndSettle();

    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Concluir'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
  });
}
