// Regression coverage for normalizeImportedPhone: phone numbers imported
// from the device's Contacts app commonly include spaces, parentheses and
// hyphens (e.g. "+351 912 345 678"), which fail the add-client form's phone
// validator (`^\+?\d+$`) if written into the field as-is. This function must
// always strip everything except digits and, when the original number
// started with '+', a single leading '+' — never inventing a country code
// (unlike normalizePhoneForWhatsApp, which is for a different purpose).
import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/services/contact_import_service.dart';

void main() {
  group('normalizeImportedPhone', () {
    test('strips spaces from a "+351 912 345 678"-style number', () {
      expect(normalizeImportedPhone('+351 912 345 678'), '+351912345678');
    });

    test('strips parentheses and hyphens from a local-style number', () {
      expect(normalizeImportedPhone('(912) 345-678'), '912345678');
    });

    test('collapses a doubled leading "+"', () {
      expect(normalizeImportedPhone('++351912345678'), '+351912345678');
    });

    test('a stray embedded "+" is removed and not treated as a leading one', () {
      expect(normalizeImportedPhone('351+912345678'), '351912345678');
    });

    test('a garbage/non-numeric value normalizes to an empty string', () {
      expect(normalizeImportedPhone('N/A'), '');
    });

    test('an empty or blank value normalizes to an empty string', () {
      expect(normalizeImportedPhone(''), '');
      expect(normalizeImportedPhone('   '), '');
    });

    test('result always matches the form phone validator regex when non-empty', () {
      final result = normalizeImportedPhone('+351 912 345 678');
      expect(RegExp(r'^\+?\d+$').hasMatch(result), isTrue);
    });
  });
}
