import 'package:test/test.dart';
import 'package:pokerd/src/card.dart';

void main() {
  group('Card', () {
    test('test_init', () {
      const card = Card(CardRank.r2, CardSuite.cross);
      expect(card.rank, equals(CardRank.r2));
      expect(card.suite, equals(CardSuite.cross));
    });

    test('test_str', () {
      const card = Card(CardRank.r8, CardSuite.cross);
      expect(card.toString(), equals('eight of cross'));
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
