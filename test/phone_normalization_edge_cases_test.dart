// Regression coverage for a robustness fix to normalizePhoneForWhatsApp:
// the function must always return a digits-only string (required by wa.me),
// even given malformed input with a '+' not at the very start, a doubled
// leading '+', or a trailing '+'. The previous implementation only ever
// stripped exactly one leading '+', leaving stray '+' characters in some
// inputs; it now strips all of them and re-applies the bare-9-digit ->
// assume-Portugal heuristic against the fully-cleaned digit string.
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/services/report_service.dart';

void main() {
  group('normalizePhoneForWhatsApp always returns digits only', () {
    test('leading "+" plus a stray embedded "+": both are stripped', () {
      final result = normalizePhoneForWhatsApp('+351+912345678');
      expect(result, '351912345678');
      expect(RegExp(r'^\d+$').hasMatch(result), isTrue);
    });

    test('doubled leading "+": both are stripped', () {
      final result = normalizePhoneForWhatsApp('++351912345678');
      expect(result, '351912345678');
    });

    test('a "+" with no recognized prefix shape: still stripped', () {
      final result = normalizePhoneForWhatsApp('351+912345678');
      expect(result, '351912345678');
    });

    test('a trailing "+": stripped, and the remaining 9 digits still get '
        'the Portugal country-code assumption applied', () {
      final result = normalizePhoneForWhatsApp('912345678+');
      expect(result, '351912345678');
    });
  });
}
