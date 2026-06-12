import 'package:pokerd/src/card.dart';
import 'package:test/test.dart';

void main() {
  group('Card', () {
    test('test_init', () {
      const card = Card(CardRank.r2, CardSuite.club);
      expect(card.rank, equals(CardRank.r2));
      expect(card.suite, equals(CardSuite.club));
    });

    test('test_str', () {
      const card = Card(CardRank.r8, CardSuite.club);
      expect(card.toString(), equals('eight of club'));
    });

    test('test_eq', () {
      const cardA = Card(CardRank.r5, CardSuite.heart);
      const cardB = Card(CardRank.r5, CardSuite.heart);
      const cardC = Card(CardRank.r8, CardSuite.heart);

      expect(cardA, equals(cardB));
      expect(cardA, isNot(equals(cardC)));
    });
  });
}
