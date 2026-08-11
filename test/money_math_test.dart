import 'package:flutter_test/flutter_test.dart';
import 'package:sharedpreferences/services/money_math.dart';

void main() {
  group('toCents/fromCents', () {
    test('exact conversion', () {
      expect(toCents(0), 0);
      expect(toCents(0.01), 1);
      expect(toCents(1000000.99), 100000099);
      expect(fromCents(30), 0.3);
    });

    test('double drift is eliminated', () {
      final sum = 0.1 + 0.2;
      expect(sum, isNot(0.3));
      expect(fromCents(toCents(sum)), 0.3);
    });

    test('rounding to nearest cent', () {
      expect(toCents(1.004), 100);
      expect(toCents(1.005), 100);
      expect(toCents(1.006), 101);
      expect(toCents(-0.006), -1);
    });
  });

  group('formatMoney', () {
    test('keeps decimals and adds thousands separators', () {
      expect(formatMoney(1234.5), '1,234.5');
      expect(formatMoney(1234.56), '1,234.56');
      expect(formatMoney(1000000.99), '1,000,000.99');
      expect(formatMoney(1234), '1,234');
      expect(formatMoney(0), '0');
      expect(formatMoney(0.5), '0.5');
    });
  });

  group('repeat add/subtract on a running balance', () {
    test('accumulates 0.01 exactly 100 times to 1.00', () {
      int balance = 0;
      for (int i = 0; i < 100; i++) {
        balance += toCents(0.01);
      }
      expect(fromCents(balance), 1.0);
    });

    test('add then subtract returns to original balance', () {
      int balance = toCents(999.99);
      balance += toCents(0.01);
      expect(fromCents(balance), 1000.0);
      balance -= toCents(0.01);
      expect(fromCents(balance), 999.99);
    });
  });
}
