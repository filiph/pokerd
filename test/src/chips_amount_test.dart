import 'package:pokerd/src/chips_amount.dart';
import 'package:test/test.dart';

void main() {
  group('ChipsAmount', () {
    test('toString() formats correctly', () {
      expect(const ChipsAmount(0).toString(), equals('\$0'));
      expect(const ChipsAmount(1500).toString(), equals('\$1,500'));
      expect(const ChipsAmount(1000000).toString(), equals('\$1,000,000'));
    });

    test('operator + works', () {
      expect(
        const ChipsAmount(100) + const ChipsAmount(200),
        equals(const ChipsAmount(300)),
      );
    });

    test('operator - works', () {
      expect(
        const ChipsAmount(500) - const ChipsAmount(200),
        equals(const ChipsAmount(300)),
      );
    });

    test('comparison operators work', () {
      expect(const ChipsAmount(100) < const ChipsAmount(200), isTrue);
      expect(const ChipsAmount(200) > const ChipsAmount(100), isTrue);
      expect(const ChipsAmount(100) <= const ChipsAmount(100), isTrue);
      expect(const ChipsAmount(100) >= const ChipsAmount(100), isTrue);
    });

    test('equality works', () {
      expect(const ChipsAmount(100), equals(const ChipsAmount(100)));
      expect(const ChipsAmount(100), isNot(equals(const ChipsAmount(200))));
    });
  });
}
