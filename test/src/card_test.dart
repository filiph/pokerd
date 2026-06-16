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

    test('pokerNotation returns correct format for various cards', () {
      expect(const Card(CardRank.a, CardSuite.heart).pokerNotation, 'Ah');
      expect(const Card(CardRank.k, CardSuite.diamond).pokerNotation, 'Kd');
      expect(const Card(CardRank.q, CardSuite.spade).pokerNotation, 'Qs');
      expect(const Card(CardRank.j, CardSuite.club).pokerNotation, 'Jc');
      expect(const Card(CardRank.r10, CardSuite.heart).pokerNotation, 'Th');
      expect(const Card(CardRank.r9, CardSuite.diamond).pokerNotation, '9d');
      expect(const Card(CardRank.r8, CardSuite.spade).pokerNotation, '8s');
      expect(const Card(CardRank.r7, CardSuite.club).pokerNotation, '7c');
      expect(const Card(CardRank.r6, CardSuite.heart).pokerNotation, '6h');
      expect(const Card(CardRank.r5, CardSuite.diamond).pokerNotation, '5d');
      expect(const Card(CardRank.r4, CardSuite.spade).pokerNotation, '4s');
      expect(const Card(CardRank.r3, CardSuite.club).pokerNotation, '3c');
      expect(const Card(CardRank.r2, CardSuite.heart).pokerNotation, '2h');
    });

    test('pokerNotation handles all suits correctly', () {
      expect(const Card(CardRank.a, CardSuite.club).pokerNotation, 'Ac');
      expect(const Card(CardRank.a, CardSuite.diamond).pokerNotation, 'Ad');
      expect(const Card(CardRank.a, CardSuite.heart).pokerNotation, 'Ah');
      expect(const Card(CardRank.a, CardSuite.spade).pokerNotation, 'As');
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
