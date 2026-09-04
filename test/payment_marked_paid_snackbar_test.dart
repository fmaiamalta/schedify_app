// Regression coverage for a real-device-testing finding: the snackbar shown
// after successfully marking a payment as paid reused
// AppStrings.confirmPaymentBody (the CONFIRMATION DIALOG'S question, e.g.
// "Mark the payment for X (Y) as completed?") instead of an actual success
// message. Fixed with a dedicated AppStrings.paymentMarkedPaidSnackbar,
// wired in home_shell.dart's _markGroupPaid.
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/i18n/app_strings.dart';
import 'package:schedify_app/models.dart';

void main() {
  test('paymentMarkedPaidSnackbar is a statement, not the confirmation dialog\'s question', () {
    final s = AppStrings(AppLanguage.pt);
    final snackbarText = s.paymentMarkedPaidSnackbar('Ana', 'Janeiro 2026');
    final dialogQuestion = s.confirmPaymentBody('Ana', 'Janeiro 2026');

    expect(snackbarText, isNot(dialogQuestion));
    expect(snackbarText, isNot(contains('?')));
    expect(snackbarText, contains('Ana'));
    expect(snackbarText, contains('Janeiro 2026'));
  });

  test('same holds in English', () {
    final s = AppStrings(AppLanguage.en);
    final snackbarText = s.paymentMarkedPaidSnackbar('Ana', 'January 2026');
    final dialogQuestion = s.confirmPaymentBody('Ana', 'January 2026');

    expect(snackbarText, isNot(dialogQuestion));
    expect(snackbarText, isNot(contains('?')));
  });
}
