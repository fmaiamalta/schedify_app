// Regression coverage for two more gender-agreement fixes found alongside
// the registeredSnackbar/noneRecordedYet fix:
//
// 1. AppStrings.paidLabel({masculine}) (was a plain "paid" getter always
//    returning "Pago") -- now agrees with ActivityLabels.sessionIsMasculine,
//    used in client_detail_screen.dart's _SessionMiniCard.
//
// 2. AppStrings.subjectsCreated now accepts {masculine}, driven by the new
//    ActivityLabels.serviceTypeIsMasculine (true only for Other Services'
//    "Serviço"), used in subjects_tab.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/i18n/app_strings.dart';
import 'package:schedify_app/models.dart';

void main() {
  final s = AppStrings(AppLanguage.pt);

  group('AppStrings.paidLabel — agrees with sessionIsMasculine', () {
    test('feminine (default): "Paga"', () {
      expect(s.paidLabel(), 'Paga');
    });

    test('masculine (Fitness/Treino): "Pago"', () {
      expect(s.paidLabel(masculine: true), 'Pago');
    });

    test('matches ActivityLabels.sessionIsMasculine for every activity type', () {
      for (final type in ActivityType.values) {
        final labels = getLabels(type);
        final expected = labels.sessionIsMasculine ? 'Pago' : 'Paga';
        expect(s.paidLabel(masculine: labels.sessionIsMasculine), expected,
            reason: '$type: sessionSingular="${labels.sessionSingular}"');
      }
    });
  });

  group('AppStrings.subjectsCreated — agrees with serviceTypeIsMasculine', () {
    test('Education (Disciplina, feminine): "registadas"', () {
      expect(getLabels(ActivityType.education).serviceTypeLabel, 'Disciplina');
      expect(s.subjectsCreated(3), '3 registadas');
    });

    test('Other Services (Serviço, masculine): "registados"', () {
      expect(getLabels(ActivityType.otherServices).serviceTypeLabel, 'Serviço');
      expect(s.subjectsCreated(3, masculine: true), '3 registados');
    });
  });
}
