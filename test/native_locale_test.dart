// Regression coverage for a real-device-testing finding: native Material
// widgets (showDatePicker's calendar/buttons) always rendered in English
// regardless of the app's own language setting, because MaterialApp never
// registered flutter_localizations delegates/supportedLocales, and the
// app's AppLanguage was never wired to MaterialApp.locale at all. Fixed via
// a global currentAppLanguage ValueNotifier (models.dart) that SchedifyApp
// listens to.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/main.dart';
import 'package:schedify_app/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    currentAppLanguage.value = AppLanguage.pt;
  });

  testWidgets('MaterialApp.locale follows currentAppLanguage, including live changes', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    currentAppLanguage.value = AppLanguage.pt;

    await tester.pumpWidget(const SchedifyApp());
    await tester.pumpAndSettle();

    var context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context), const Locale('pt'));

    currentAppLanguage.value = AppLanguage.en;
    await tester.pumpAndSettle();

    context = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(context), const Locale('en'));
  });

  test('localeFor maps AppLanguage to the matching Locale', () {
    expect(localeFor(AppLanguage.pt), const Locale('pt'));
    expect(localeFor(AppLanguage.en), const Locale('en'));
  });
}
