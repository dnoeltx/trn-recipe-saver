// Tests for Quantity (FR-002, FR-008, research R9). Written before the
// implementation, per constitution Principle IX.
import 'package:test/test.dart';
import 'package:trn_core/trn_core.dart';

void main() {
  group('Quantity.parse accepts', () {
    test('a whole number', () {
      final q = Quantity.parse('2');
      expect(q.numerator, 2);
      expect(q.denominator, 1);
      expect(q.form, QuantityForm.whole);
    });

    test('a decimal', () {
      final q = Quantity.parse('0.5');
      expect(q.numerator, 1);
      expect(q.denominator, 2);
      expect(q.form, QuantityForm.decimal);
    });

    test('a decimal without a leading zero', () {
      expect(Quantity.parse('.25').isSameAmountAs(Quantity.parse('1/4')), isTrue);
    });

    test('a fraction', () {
      final q = Quantity.parse('1/3');
      expect(q.numerator, 1);
      expect(q.denominator, 3);
      expect(q.form, QuantityForm.fraction);
    });

    test('a mixed number', () {
      final q = Quantity.parse('1 1/2');
      expect(q.numerator, 3);
      expect(q.denominator, 2);
      expect(q.form, QuantityForm.mixed);
    });

    test('surrounding and repeated spaces', () {
      expect(Quantity.parse('  1   1/2 ').isSameAmountAs(Quantity.parse('3/2')), isTrue);
    });

    test('a fraction in lowest terms only after reducing', () {
      final q = Quantity.parse('2/4');
      expect(q.numerator, 1);
      expect(q.denominator, 2);
    });
  });

  group('Quantity.parse rejects', () {
    for (final text in [
      '',
      '   ',
      'abc',
      '1/0',
      '0',
      '0/3',
      '-1',
      '1/2/3',
      '1 2',
      '1 1/0',
      '0 1/2',
      '1 3/2',
      '1.2.3',
      '2 cups',
    ]) {
      test('"$text"', () {
        expect(() => Quantity.parse(text), throwsFormatException);
        expect(Quantity.tryParse(text), isNull);
      });
    }
  });

  group('arithmetic is exact', () {
    test('thirds add up to exactly one', () {
      final third = Quantity.parse('1/3');
      expect((third + third + third).isSameAmountAs(Quantity.parse('1')), isTrue);
    });

    test('mixed forms add by value', () {
      final sum = Quantity.parse('0.5') + Quantity.parse('1 1/4');
      expect(sum.isSameAmountAs(Quantity.parse('7/4')), isTrue);
    });

    test('a near miss is not the same amount', () {
      final sum = Quantity.parse('1/3') + Quantity.parse('1/3') + Quantity.parse('0.33');
      expect(sum.isSameAmountAs(Quantity.parse('1')), isFalse);
    });
  });

  group('format returns the form entered', () {
    for (final text in ['2', '0.5', '1.25', '1/3', '3/2', '1 1/2', '2 2/3']) {
      test('"$text"', () {
        expect(Quantity.parse(text).format(), text);
      });
    }

    test('a reduced fraction is shown reduced', () {
      expect(Quantity.parse('2/4').format(), '1/2');
    });
  });

  group('equality', () {
    test('same amount and form are equal', () {
      expect(Quantity.parse('1/2'), equals(Quantity.parse('2/4')));
    });

    test('same amount in a different form is not equal, but is the same amount', () {
      final half = Quantity.parse('1/2');
      final point5 = Quantity.parse('0.5');
      expect(half, isNot(equals(point5)));
      expect(half.isSameAmountAs(point5), isTrue);
    });
  });
}
