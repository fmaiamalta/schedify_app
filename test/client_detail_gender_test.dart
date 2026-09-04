// Regression coverage: client_detail_screen.dart's "Configuração da/do X"
// section title was calling sessionConfigSection without the masculine
// parameter, so Fitness ("Treino") showed "Configuração da Treino" instead
// of "Configuração do Treino", even though the equally-fixed create-form
// screen already got this right this session.
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/i18n/app_strings.dart';
import 'package:schedify_app/models.dart';

void main() {
  final s = AppStrings(AppLanguage.pt);

  test('sessionConfigSection agrees with sessionIsMasculine for every activity type', () {
    for (final type in ActivityType.values) {
      final labels = getLabels(type);
      final title = s.sessionConfigSection(labels.sessionSingular, masculine: labels.sessionIsMasculine);
      final expectedArticle = labels.sessionIsMasculine ? 'Configuração do' : 'Configuração da';
      expect(title, startsWith(expectedArticle), reason: '$type: sessionSingular="${labels.sessionSingular}"');
    }
  });
}
