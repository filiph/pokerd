import 'package:test/test.dart';
import 'package:pokerd/src/card.dart';
import 'package:pokerd/src/deck.dart';

void main() {
  group('Deck', () {
    test('test_init', () {
      final deck = Deck();
      expect(deck.cards.length, equals(52));
    });

    test('test_refill', () {
      final deck = Deck();
      deck.cards = [];
      deck.refill();

      expect(deck.cards.length, equals(52));

      final suitCounts = <CardSuite, int>{};
      final rankCounts = <CardRank, int>{};

      for (final card in deck.cards) {
        suitCounts[card.suite] = (suitCounts[card.suite] ?? 0) + 1;
        rankCounts[card.rank] = (rankCounts[card.rank] ?? 0) + 1;
      }

      for (final count in suitCounts.values) {
        expect(count, equals(13));
      }
      for (final count in rankCounts.values) {
        expect(count, equals(4));
      }
      expect(deck.cards.toSet().length, equals(52));
    });

    test('test_shuffle', () {
      final deck = Deck();
      final cardsBefore = List<Card>.from(deck.cards);

      deck.shuffle();

      var differences = 0;
      for (var i = 0; i < cardsBefore.length; i++) {
        if (cardsBefore[i] != deck.cards[i]) {
          differences++;
        }
      }
      expect(differences, greaterThan(0));
    });

    test('test_burn', () {
      final deck = Deck();
      deck.cards = [
        const Card(CardRank.r2, CardSuite.cross),
        const Card(CardRank.r3, CardSuite.cross),
      ];

      deck.burn();

      expect(deck.cards.length, equals(1));
    });

    test('test_str', () {
      final deck = Deck();
      deck.cards = [
        const Card(CardRank.r5, CardSuite.heart),
        const Card(CardRank.k, CardSuite.diamond),
        const Card(CardRank.r8, CardSuite.spade),
      ];

      expect(deck.toString(), equals('[5 ♥] [K ♦] [8 ♠]'));
    });
  });
}
