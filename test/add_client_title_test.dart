// Regression coverage for a real-device-testing finding: AddClientScreen's
// AppBar title used the full compound label (e.g. "Novo Aluno/Formando" for
// Education) with no overflow handling, clipping on both iOS and Android.
// Fixed by using shortCompoundLabel (the same technique already used for the
// bottom nav labels) plus a maxLines/ellipsis safety net.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/models.dart';
import 'package:schedify_app/screens/add_client_screen.dart';

void main() {
  testWidgets('new-client title uses the short compound label, not the full "Aluno/Formando"', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AddClientScreen(activityType: ActivityType.education, language: AppLanguage.pt),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Novo Aluno'), findsOneWidget);
    expect(find.text('Novo Aluno/Formando'), findsNothing);
  });

  test('shortCompoundLabel keeps only the first segment', () {
    expect(shortCompoundLabel('Aluno/Formando'), 'Aluno');
    expect(shortCompoundLabel('Especialidade / Tipo de consulta'), 'Especialidade');
    expect(shortCompoundLabel('Serviço'), 'Serviço');
  });
}
