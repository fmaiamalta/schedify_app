import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/i18n/app_strings.dart';
import 'package:schedify_app/models.dart';

void main() {
  final s = AppStrings(AppLanguage.pt);

  group('registeredSnackbar — concordância de género em pt-PT', () {
    test('feminino (Aula/Consulta/Sessão): "registada"', () {
      expect(s.registeredSnackbar('Aula', 'Ana'), 'Aula registada para Ana');
    });

    test('masculino (Treino, Fitness): "registado"', () {
      expect(s.registeredSnackbar('Treino', 'Ana', masculine: true), 'Treino registado para Ana');
    });
  });

  group('noneRecordedYet — concordância de género em pt-PT', () {
    test('feminino: "registadas"', () {
      expect(s.noneRecordedYet('aulas'), 'Ainda não há aulas registadas.');
    });

    test('masculino (Treinos, Fitness): "registados"', () {
      expect(s.noneRecordedYet('treinos', masculine: true), 'Ainda não há treinos registados.');
    });
  });

  test('só Fitness tem sessionIsMasculine true; as restantes são femininas', () {
    for (final type in ActivityType.values) {
      final labels = getLabels(type);
      expect(labels.sessionIsMasculine, type == ActivityType.fitness,
          reason: '$type: sessionSingular="${labels.sessionSingular}"');
    }
  });
}
