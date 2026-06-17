import 'dart:math';

import 'package:pokerd/src/betting_move.dart';
import 'package:pokerd/src/card.dart';
import 'package:pokerd/src/chips_amount.dart';
import 'package:pokerd/src/computer_player.dart';
import 'package:test/test.dart';

void main() {
  group('ComputerPlayer Archetypes', () {
    late Random random;

    setUp(() {
      random = Random(42); // Fixed seed for reproducibility
    });

    test('Grandma folds weak hand pre-flop', () async {
      final player = ComputerPlayer(
        'Grandma',
        ComputerPlayingStyle.grandma,
        random: random,
        monteCarloIterations: 1000,
      );
      player.hand = [
        const Card(CardRank.r2, CardSuite.spade),
        const Card(CardRank.r7, CardSuite.heart),
      ];
      // Table has a bet of 200, Grandma has 0.
      player.bet = const ChipsAmount(0);
      player.chips = const ChipsAmount(10000);
      final move = await player.chooseNextMove(
        const ChipsAmount(400),
        0,
        const ChipsAmount(200),
        community: [],
        potSize: const ChipsAmount(300),
        otherBets: [const ChipsAmount(200)],
      );
      expect(move, equals(BettingMove.folded));
    });

    test('Grandma calls with very strong hand', () async {
      final player = ComputerPlayer(
        'Grandma',
        ComputerPlayingStyle.grandma,
        random: random,
        monteCarloIterations: 1000,
      );
      player.hand = [
        const Card(CardRank.a, CardSuite.spade),
        const Card(CardRank.a, CardSuite.heart),
      ];
      player.bet = const ChipsAmount(0);
      player.chips = const ChipsAmount(10000);
      final move = await player.chooseNextMove(
        const ChipsAmount(400),
        0,
        const ChipsAmount(200),
        community: [],
        potSize: const ChipsAmount(300),
        otherBets: [const ChipsAmount(200)],
      );
      // AA preflop is > 80% win prob vs 1 opponent
      expect(move, equals(BettingMove.called));
    });

    test('Leeroy bets pre-flop with mediocre hand', () async {
      final player = ComputerPlayer(
        'Leeroy',
        ComputerPlayingStyle.leeroy,
        random: random,
        monteCarloIterations: 1000,
      );
      player.hand = [
        const Card(CardRank.j, CardSuite.spade),
        const Card(CardRank.r10, CardSuite.heart),
      ];
      player.bet = const ChipsAmount(0);
      player.chips = const ChipsAmount(10000);
      final move = await player.chooseNextMove(
        const ChipsAmount(200),
        0,
        const ChipsAmount(0),
        community: [],
        potSize: const ChipsAmount(0),
        otherBets: [const ChipsAmount(0)],
      );
      expect(move, equals(BettingMove.bet));
    });

    test('Mr. Suitcase calls when pot odds are favorable', () async {
      final player = ComputerPlayer(
        'Mr. Suitcase',
        ComputerPlayingStyle.mrCase,
        random: random,
        monteCarloIterations: 1000,
      );
      // Flush draw
      player.hand = [
        const Card(CardRank.r2, CardSuite.heart),
        const Card(CardRank.r3, CardSuite.heart),
      ];
      final community = [
        const Card(CardRank.a, CardSuite.heart),
        const Card(CardRank.k, CardSuite.heart),
        const Card(CardRank.q, CardSuite.spade),
      ];
      player.bet = const ChipsAmount(0);
      player.chips = const ChipsAmount(10000);
      // Pot is 1000, call is 100. Pot odds = 100/1100 ~= 0.09.
      // Win prob for flush draw (9 outs) is ~35% over 2 cards.
      final move = await player.chooseNextMove(
        const ChipsAmount(200),
        0,
        const ChipsAmount(100),
        community: community,
        potSize: const ChipsAmount(1000),
        otherBets: [const ChipsAmount(100)],
      );
      expect(move, anyOf(BettingMove.called, BettingMove.raised));
    });

    test('Mr. Suitcase folds when pot odds are unfavorable', () async {
      final player = ComputerPlayer(
        'Mr. Suitcase',
        ComputerPlayingStyle.mrCase,
        random: random,
        monteCarloIterations: 1000,
      );
      player.hand = [
        const Card(CardRank.r2, CardSuite.spade),
        const Card(CardRank.r7, CardSuite.heart),
      ];
      player.bet = const ChipsAmount(0);
      player.chips = const ChipsAmount(10000);
      // Huge bet, low win prob
      final move = await player.chooseNextMove(
        const ChipsAmount(2000),
        0,
        const ChipsAmount(2000),
        community: [],
        potSize: const ChipsAmount(100),
        otherBets: [const ChipsAmount(2000)],
      );
      expect(move, equals(BettingMove.folded));
    });

    test('Error field introduces irrationality', () async {
      // With high error, Grandma might NOT fold a weak hand (though unlikely to happen every time, we can test jitter)
      final player = ComputerPlayer(
        'Grandma',
        ComputerPlayingStyle.grandma,
        error: 1.0,
        random: random,
        monteCarloIterations: 1000,
      );
      player.hand = [
        const Card(CardRank.r2, CardSuite.spade),
        const Card(CardRank.r7, CardSuite.heart),
      ];
      player.bet = const ChipsAmount(0);
      player.chips = const ChipsAmount(10000);

      // We run it a few times to see if she ever DOESN'T fold
      var didNotFold = false;
      for (var i = 0; i < 20; i++) {
        final move = await player.chooseNextMove(
          const ChipsAmount(400),
          0,
          const ChipsAmount(200),
          community: [],
          potSize: const ChipsAmount(300),
          otherBets: [const ChipsAmount(200)],
        );
        if (move != BettingMove.folded) {
          didNotFold = true;
          break;
        }
      }
      expect(
        didNotFold,
        isTrue,
        reason:
            'With error 1.0, Grandma should eventually do something irrational',
      );
    });

    test('Michelle folds when someone bets huge relative to pot', () async {
      final player = ComputerPlayer(
        'Michelle',
        ComputerPlayingStyle.michelle,
        random: random,
        monteCarloIterations: 1000,
      );
      // Mediocre hand: pair of Jacks
      player.hand = [
        const Card(CardRank.j, CardSuite.spade),
        const Card(CardRank.j, CardSuite.heart),
      ];
      final community = [
        const Card(CardRank.a, CardSuite.diamond),
        const Card(CardRank.k, CardSuite.diamond),
        const Card(CardRank.r2, CardSuite.club),
      ];
      player.bet = const ChipsAmount(0);
      player.chips = const ChipsAmount(10000);
      // Pot is 1000, but someone bets 5000 (huge overbet).
      // Michelle should be cautious.
      final move = await player.chooseNextMove(
        const ChipsAmount(5000),
        0,
        const ChipsAmount(5000),
        community: community,
        potSize: const ChipsAmount(1000),
        otherBets: [const ChipsAmount(5000)],
      );
      expect(move, equals(BettingMove.folded));
    });

    test(
      'ComputerPlayer returns all-in when it wants to call but is short',
      () async {
        final player = ComputerPlayer(
          'Michelle',
          ComputerPlayingStyle.michelle,
          random: random,
          monteCarloIterations: 1000,
        );
        player.hand = [
          const Card(CardRank.a, CardSuite.spade),
          const Card(CardRank.a, CardSuite.heart),
        ];
        player.bet = const ChipsAmount(0);
        player.chips = const ChipsAmount(1000);

        // Need to call 2000, but only has 1000.
        final move = await player.chooseNextMove(
          const ChipsAmount(2000),
          0,
          const ChipsAmount(2000),
          community: [],
          potSize: const ChipsAmount(10000),
          otherBets: [const ChipsAmount(2000)],
        );
        expect(move, equals(BettingMove.allIn));
      },
    );
  });
}
