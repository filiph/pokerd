import 'package:test/test.dart';
import 'package:pokerd/src/card.dart';
import 'package:pokerd/src/player.dart';
import 'package:pokerd/src/betting_move.dart';
import 'package:pokerd/src/hand_rank.dart';

class TestPlayer extends Player {
  TestPlayer(super.name);

  @override
  BettingMove chooseNextMove(
    int tableRaiseAmount,
    int numTimesTableRaised,
    int tableLastBet,
  ) {
    return BettingMove.checked;
  }
}

void main() {
  group('Hand Ranking Utils', () {
    group('Combinations Utility', () {
      test('test combinations generation of 5 from 7', () {
        final cards = [
          const Card(CardRank.a, CardSuite.spade),
          const Card(CardRank.k, CardSuite.spade),
          const Card(CardRank.q, CardSuite.spade),
          const Card(CardRank.j, CardSuite.spade),
          const Card(CardRank.r10, CardSuite.spade),
          const Card(CardRank.r9, CardSuite.spade),
          const Card(CardRank.r8, CardSuite.spade),
        ];

        final combos = HandRank.getCombinations(cards, 5);
        expect(combos.length, equals(21)); // 7 choose 5 = 21
        for (final combo in combos) {
          expect(combo.length, equals(5));
          expect(combo.toSet().length, equals(5));
        }
      });
    });

    group('Hand Scoring', () {
      test('Royal Flush', () {
        final hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.k, CardSuite.heart),
          const Card(CardRank.q, CardSuite.heart),
          const Card(CardRank.j, CardSuite.heart),
          const Card(CardRank.r10, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(100000000000));
      });

      test('Straight Flush', () {
        final hand = [
          const Card(CardRank.k, CardSuite.heart),
          const Card(CardRank.q, CardSuite.heart),
          const Card(CardRank.j, CardSuite.heart),
          const Card(CardRank.r10, CardSuite.heart),
          const Card(CardRank.r9, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(91300000000));
      });

      test('Four of a Kind', () {
        final hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.a, CardSuite.spade),
          const Card(CardRank.a, CardSuite.diamond),
          const Card(CardRank.a, CardSuite.club),
          const Card(CardRank.k, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(81413000000));
      });

      test('Full House', () {
        final hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.a, CardSuite.spade),
          const Card(CardRank.a, CardSuite.diamond),
          const Card(CardRank.k, CardSuite.club),
          const Card(CardRank.k, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(71413000000));
      });

      test('Flush', () {
        final hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.j, CardSuite.heart),
          const Card(CardRank.r9, CardSuite.heart),
          const Card(CardRank.r8, CardSuite.heart),
          const Card(CardRank.r2, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(61411090802));
      });

      test('Straight', () {
        final hand = [
          const Card(CardRank.q, CardSuite.heart),
          const Card(CardRank.j, CardSuite.spade),
          const Card(CardRank.r10, CardSuite.diamond),
          const Card(CardRank.r9, CardSuite.club),
          const Card(CardRank.r8, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(51200000000));
      });

      test('Three of a Kind', () {
        final hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.a, CardSuite.spade),
          const Card(CardRank.a, CardSuite.diamond),
          const Card(CardRank.k, CardSuite.club),
          const Card(CardRank.q, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(41413120000));
      });

      test('Two Pair', () {
        final hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.a, CardSuite.spade),
          const Card(CardRank.k, CardSuite.diamond),
          const Card(CardRank.k, CardSuite.club),
          const Card(CardRank.q, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(31413120000));
      });

      test('One Pair', () {
        final hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.a, CardSuite.spade),
          const Card(CardRank.k, CardSuite.diamond),
          const Card(CardRank.q, CardSuite.club),
          const Card(CardRank.j, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(21413121100));
      });

      test('High Card', () {
        final hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.k, CardSuite.spade),
          const Card(CardRank.q, CardSuite.diamond),
          const Card(CardRank.j, CardSuite.club),
          const Card(CardRank.r9, CardSuite.heart),
        ];
        expect(HandRank.scoreHand(hand), equals(11413121109));
      });
    });

    group('Showdown Winner & Kicker', () {
      test('Determine showdown winner without tie', () {
        final p1 = TestPlayer('Player 1')..hand = [
          const Card(CardRank.a, CardSuite.heart),
          const Card(CardRank.k, CardSuite.spade),
        ];
        final p2 = TestPlayer('Player 2')..hand = [
          const Card(CardRank.r2, CardSuite.heart),
          const Card(CardRank.r3, CardSuite.spade),
        ];
        final community = [
          const Card(CardRank.q, CardSuite.diamond),
          const Card(CardRank.j, CardSuite.club),
          const Card(CardRank.r10, CardSuite.heart),
          const Card(CardRank.r7, CardSuite.diamond),
          const Card(CardRank.r5, CardSuite.spade),
        ];

        final winners = HandRank.determineShowdownWinner([p1, p2], community);
        expect(winners.length, equals(1));
        expect(winners[0].name, equals('Player 1'));
        expect(p1.bestHandRank, equals(HandRank.straight));
        expect(p1.rankSubtype, equals(': Ace high'));
      });

      test('Determine showdown winner with kicker tie-breaker (One Pair)', () {
        final p1 = TestPlayer('Player A')..hand = [
          const Card(CardRank.k, CardSuite.spade),
          const Card(CardRank.r8, CardSuite.heart),
        ];
        final p2 = TestPlayer('Player B')..hand = [
          const Card(CardRank.k, CardSuite.club),
          const Card(CardRank.r6, CardSuite.club),
        ];
        final community = [
          const Card(CardRank.k, CardSuite.heart),
          const Card(CardRank.r2, CardSuite.club),
          const Card(CardRank.r10, CardSuite.club),
          const Card(CardRank.r5, CardSuite.spade),
          const Card(CardRank.j, CardSuite.heart),
        ];

        final winners = HandRank.determineShowdownWinner([p1, p2], community);
        expect(winners.length, equals(1));
        expect(winners[0].name, equals('Player A'));
        expect(p1.kickerCard, isNotNull);
        expect(p1.kickerCard!.rank, equals(CardRank.r8));
      });

      test('Determine showdown winner with true tie (One Pair)', () {
        final p1 = TestPlayer('Player A')..hand = [
          const Card(CardRank.k, CardSuite.spade),
          const Card(CardRank.r8, CardSuite.heart),
        ];
        final p2 = TestPlayer('Player B')..hand = [
          const Card(CardRank.k, CardSuite.club),
          const Card(CardRank.r6, CardSuite.club),
        ];
        final community = [
          const Card(CardRank.k, CardSuite.heart),
          const Card(CardRank.q, CardSuite.club),
          const Card(CardRank.r10, CardSuite.club),
          const Card(CardRank.r5, CardSuite.spade),
          const Card(CardRank.j, CardSuite.heart),
        ];

        // Best 5 cards for both players: K, K, Q, J, 10
        final winners = HandRank.determineShowdownWinner([p1, p2], community);
        expect(winners.length, equals(2));
        expect(winners.map((p) => p.name).toSet(), equals({'Player A', 'Player B'}));
        expect(p1.kickerCard, isNull);
        expect(p2.kickerCard, isNull);
      });
    });

    group('Subtype Formatting Spells', () {
      test('Sixes formatting for Full House', () {
        final p = TestPlayer('Player 1')..bestHandScore = 70611000000..bestHandRank = HandRank.fullHouse;
        HandRank.assignHandrankSubtypes([p]);
        expect(p.rankSubtype, equals(': Sixes over Jacks'));
      });

      test('Sixes formatting for Two Pair', () {
        final p = TestPlayer('Player 1')..bestHandScore = 31106020000..bestHandRank = HandRank.twoPair;
        HandRank.assignHandrankSubtypes([p]);
        expect(p.rankSubtype, equals(': Jacks and Sixes'));
      });
    });
  });
}
