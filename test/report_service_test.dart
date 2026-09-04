import 'package:flutter_test/flutter_test.dart';
import 'package:schedify_app/services/report_service.dart';

void main() {
  group('normalizePhoneForWhatsApp', () {
    test('assumes +351 for a bare 9-digit Portuguese mobile number', () {
      expect(normalizePhoneForWhatsApp('912345678'), '351912345678');
    });

    test('respects an explicit + country code as-is', () {
      expect(normalizePhoneForWhatsApp('+44 7911 123456'), '447911123456');
    });

    test('respects an explicit 00 country-code prefix', () {
      expect(normalizePhoneForWhatsApp('00447911123456'), '447911123456');
    });

    test('leaves an already-international number (not 9 digits) untouched', () {
      expect(normalizePhoneForWhatsApp('351912345678'), '351912345678');
    });
  });
}
