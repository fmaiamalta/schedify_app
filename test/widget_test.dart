// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schedify_app/main.dart';

void main() {
  testWidgets('A app arranca corretamente', (WidgetTester tester) async {
    // Sem isto, SharedPreferences.getInstance() fica bloqueado para sempre
    // dentro de testWidgets (não usa a plataforma real nem lança erro).
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SchedifyApp());
    await tester.pumpAndSettle();

    expect(find.text('Escolha o tipo de atividade'), findsOneWidget);
  });
}
