import 'dart:math';
import 'package:test/test.dart';
import 'package:pokerd/src/computer_player.dart';
import 'package:pokerd/src/betting_move.dart';

class FakeRandom implements Random {
  final double doubleValue;
  FakeRandom(this.doubleValue);

  @override
  double nextDouble() => doubleValue;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  int nextInt(int max) => throw UnimplementedError();
}

void main() {
  group('ComputerPlayer - Risky Play Style', () {
    test('goes all-in rare but possible when bet == tableLastBet', () async {
      final player = ComputerPlayer(
        'RiskyBot',
        ComputerPlayingStyle.risky,
        random: FakeRandom(0.03),
      );
      player.chips = 1000;
      player.bet = 0;
      final move = await player.chooseNextMove(200, 0, 0);
      expect(move, equals(BettingMove.allIn));
    });

    test('performs check/bet/fold when x is larger', () async {
      // Checked
      final playerCheck = ComputerPlayer(
        'RiskyBot',
        ComputerPlayingStyle.risky,
        random: FakeRandom(0.20),
      );
      playerCheck.chips = 1000;
      playerCheck.bet = 0;
      expect(
        await playerCheck.chooseNextMove(200, 0, 0),
        equals(BettingMove.checked),
      );

      // Bet
      final playerBet = ComputerPlayer(
        'RiskyBot',
        ComputerPlayingStyle.risky,
        random: FakeRandom(0.60),
      );
      playerBet.chips = 1000;
      playerBet.bet = 0;
      expect(
        await playerBet.chooseNextMove(200, 0, 0),
        equals(BettingMove.bet),
      );

      // Folded
      final playerFold = ComputerPlayer(
        'RiskyBot',
        ComputerPlayingStyle.risky,
        random: FakeRandom(0.95),
      );
      playerFold.chips = 1000;
      playerFold.bet = 0;
      expect(
        await playerFold.chooseNextMove(200, 0, 0),
        equals(BettingMove.folded),
      );
    });

    test('goes all-in rare but possible when bet != tableLastBet', () async {
      final player = ComputerPlayer(
        'RiskyBot',
        ComputerPlayingStyle.risky,
        random: FakeRandom(0.03),
      );
      player.chips = 1000;
      player.bet = 100;
      final move = await player.chooseNextMove(300, 1, 200);
      expect(move, equals(BettingMove.allIn));
    });

    test('goes all-in rare but possible when raise limit reached', () async {
      final player = ComputerPlayer(
        'RiskyBot',
        ComputerPlayingStyle.risky,
        random: FakeRandom(0.03),
      );
      player.chips = 1000;
      player.bet = 100;
      final move = await player.chooseNextMove(300, 4, 200);
      expect(move, equals(BettingMove.allIn));
    });
  });

  group('ComputerPlayer - Safe Play Style', () {
    test('goes all-in rare but possible when bet == tableLastBet', () async {
      final player = ComputerPlayer(
        'SafeBot',
        ComputerPlayingStyle.safe,
        random: FakeRandom(0.01),
      );
      player.chips = 1000;
      player.bet = 0;
      final move = await player.chooseNextMove(200, 0, 0);
      expect(move, equals(BettingMove.allIn));
    });

    test('performs check/bet/fold when x is larger', () async {
      // Checked
      final playerCheck = ComputerPlayer(
        'SafeBot',
        ComputerPlayingStyle.safe,
        random: FakeRandom(0.50),
      );
      playerCheck.chips = 1000;
      playerCheck.bet = 0;
      expect(
        await playerCheck.chooseNextMove(200, 0, 0),
        equals(BettingMove.checked),
      );

      // Bet
      final playerBet = ComputerPlayer(
        'SafeBot',
        ComputerPlayingStyle.safe,
        random: FakeRandom(0.80),
      );
      playerBet.chips = 1000;
      playerBet.bet = 0;
      expect(
        await playerBet.chooseNextMove(200, 0, 0),
        equals(BettingMove.bet),
      );

      // Folded
      final playerFold = ComputerPlayer(
        'SafeBot',
        ComputerPlayingStyle.safe,
        random: FakeRandom(0.95),
      );
      playerFold.chips = 1000;
      playerFold.bet = 0;
      expect(
        await playerFold.chooseNextMove(200, 0, 0),
        equals(BettingMove.folded),
      );
    });

    test('goes all-in rare but possible when bet != tableLastBet', () async {
      final player = ComputerPlayer(
        'SafeBot',
        ComputerPlayingStyle.safe,
        random: FakeRandom(0.01),
      );
      player.chips = 1000;
      player.bet = 100;
      final move = await player.chooseNextMove(300, 1, 200);
      expect(move, equals(BettingMove.allIn));
    });

    test('goes all-in rare but possible when raise limit reached', () async {
      final player = ComputerPlayer(
        'SafeBot',
        ComputerPlayingStyle.safe,
        random: FakeRandom(0.01),
      );
      player.chips = 1000;
      player.bet = 100;
      final move = await player.chooseNextMove(300, 4, 200);
      expect(move, equals(BettingMove.allIn));
    });
  });

  group('ComputerPlayer - Random Play Style', () {
    test('goes all-in rare but possible when bet == tableLastBet', () async {
      final player = ComputerPlayer(
        'RandomBot',
        ComputerPlayingStyle.random,
        random: FakeRandom(0.03),
      );
      player.chips = 1000;
      player.bet = 0;
      final move = await player.chooseNextMove(200, 0, 0);
      expect(move, equals(BettingMove.allIn));
    });

    test('performs check/bet/fold when x is larger', () async {
      // Checked
      final playerCheck = ComputerPlayer(
        'RandomBot',
        ComputerPlayingStyle.random,
        random: FakeRandom(0.20),
      );
      playerCheck.chips = 1000;
      playerCheck.bet = 0;
      expect(
        await playerCheck.chooseNextMove(200, 0, 0),
        equals(BettingMove.checked),
      );

      // Bet
      final playerBet = ComputerPlayer(
        'RandomBot',
        ComputerPlayingStyle.random,
        random: FakeRandom(0.50),
      );
      playerBet.chips = 1000;
      playerBet.bet = 0;
      expect(
        await playerBet.chooseNextMove(200, 0, 0),
        equals(BettingMove.bet),
      );

      // Folded
      final playerFold = ComputerPlayer(
        'RandomBot',
        ComputerPlayingStyle.random,
        random: FakeRandom(0.80),
      );
      playerFold.chips = 1000;
      playerFold.bet = 0;
      expect(
        await playerFold.chooseNextMove(200, 0, 0),
        equals(BettingMove.folded),
      );
    });

    test('goes all-in rare but possible when bet != tableLastBet', () async {
      final player = ComputerPlayer(
        'RandomBot',
        ComputerPlayingStyle.random,
        random: FakeRandom(0.03),
      );
      player.chips = 1000;
      player.bet = 100;
      final move = await player.chooseNextMove(300, 1, 200);
      expect(move, equals(BettingMove.allIn));
    });

    test('goes all-in rare but possible when raise limit reached', () async {
      final player = ComputerPlayer(
        'RandomBot',
        ComputerPlayingStyle.random,
        random: FakeRandom(0.03),
      );
      player.chips = 1000;
      player.bet = 100;
      final move = await player.chooseNextMove(300, 4, 200);
      expect(move, equals(BettingMove.allIn));
    });
  });
}
