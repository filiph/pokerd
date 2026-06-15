import 'package:test/test.dart';
import 'package:pokerd/src/card.dart';
import 'package:pokerd/src/player.dart';
import 'package:pokerd/src/betting_move.dart';
import 'package:pokerd/src/table.dart';
import 'package:pokerd/src/phase.dart';

class MockConcretePlayerClass extends Player {
  MockConcretePlayerClass(super.name);
}

class MockTableWithIncrease extends Table {
  @override
  bool checkIncreaseBigBlind() => true;
}

class MockTableWithoutIncrease extends Table {
  @override
  bool checkIncreaseBigBlind() => false;
}

void main() {
  group('TestTableReset', () {
    test('test_reset', () {
      final activePlayers = <Player>[MockConcretePlayerClass('John')];
      final table = Table();
      table.bigBlind = 50;
      table.community = [
        const Card(CardRank.r3, CardSuite.diamond),
        const Card(CardRank.r9, CardSuite.heart),
      ];
      table.pots = [Pot(300, activePlayers)];
      table.potTransfers = [300, 400];
      table.lastBet = 100;
      table.numTimesRaised = 1;

      table.reset(activePlayers);

      expect(table.community, isEmpty);
      expect(table.pots.length, equals(1));
      expect(table.pots[0].amount, equals(0));
      expect(table.pots[0].players, equals(activePlayers));
      expect(table.potTransfers, isEmpty);
      expect(table.lastBet, equals(0));
      expect(table.numTimesRaised, equals(0));
      expect(table.raiseAmount, equals(table.bigBlind));
    });

    test('test_reset_increases_big_blind', () {
      final table = MockTableWithIncrease();
      table.bigBlind = 50;

      table.reset([]);

      expect(table.bigBlind, equals(100));
      expect(table.raiseAmount, equals(table.bigBlind));
    });

    test('test_reset_does_not_increase_big_blind', () {
      final table = MockTableWithoutIncrease();
      table.bigBlind = 50;

      table.reset([]);

      expect(table.bigBlind, equals(50));
      expect(table.raiseAmount, equals(table.bigBlind));
    });
  });

  group('TestTableCheckIncreaseBigBlind', () {
    test('test_check_increase_big_blind_returns_true', () {
      Table.increaseBlindHandIncrements = 5;
      final table = Table();

      table.handsPlayed = 5;
      expect(table.checkIncreaseBigBlind(), isTrue);

      table.handsPlayed = 15;
      expect(table.checkIncreaseBigBlind(), isTrue);
    });

    test('test_check_increase_big_blind_returns_false', () {
      Table.increaseBlindHandIncrements = 5;
      final table = Table();

      table.handsPlayed = 0;
      expect(table.checkIncreaseBigBlind(), isFalse);

      table.handsPlayed = 4;
      expect(table.checkIncreaseBigBlind(), isFalse);

      table.handsPlayed = 11;
      expect(table.checkIncreaseBigBlind(), isFalse);
    });
  });

  group('TestTableBettingsAndBlinds', () {
    test('test_takeSmallBlind_with_sufficient_chips', () {
      final player = MockConcretePlayerClass('Alice')..chips = 1000;
      final table = Table()..bigBlind = 200;
      final result = table.takeSmallBlind(player);
      expect(result, isFalse);
      expect(player.bet, equals(100));
      expect(player.chips, equals(900));
      expect(table.lastBet, equals(100));
    });

    test('test_takeSmallBlind_forcing_all_in', () {
      final player = MockConcretePlayerClass('Alice')..chips = 50;
      final table = Table()..bigBlind = 200;
      final result = table.takeSmallBlind(player);
      expect(result, isTrue);
      expect(player.isAllIn, isTrue);
      expect(player.bet, equals(50));
      expect(player.chips, equals(0));
      expect(table.potTransfers, contains(50));
    });

    test('test_takeBet_checks_and_calls', () {
      final player = MockConcretePlayerClass('Alice')..chips = 1000;
      final table = Table()..lastBet = 150;
      table.takeBet(player, BettingMove.called);
      expect(player.bet, equals(150));
      expect(player.chips, equals(850));
    });

    test('test_updateRaiseAmount_preflop', () {
      final table = Table()
        ..bigBlind = 200
        ..lastBet = 300
        ..minRaiseIncrement = 200;
      table.updateRaiseAmount(Phase.preflop);
      expect(table.raiseAmount, equals(500));
    });

    test('test_updateRaiseAmount_turn', () {
      final table = Table()
        ..bigBlind = 200
        ..lastBet = 300
        ..minRaiseIncrement = 400;
      table.updateRaiseAmount(Phase.turn);
      expect(table.raiseAmount, equals(700));
    });

    test('test_takeBet_normal_raise_updates_minRaiseIncrement', () {
      final player = MockConcretePlayerClass('Alice')..chips = 1000;
      final table = Table()
        ..bigBlind = 200
        ..minRaiseIncrement = 200
        ..raiseAmount =
            300 // Raise from 100 to 300
        ..lastBet = 100;

      table.takeBet(player, BettingMove.raised);

      expect(table.lastBet, equals(300));
      expect(table.minRaiseIncrement, equals(200));
      expect(table.lastRaiseWasFull, isTrue);
      expect(table.numTimesRaised, equals(1));
    });

    test('test_takeBet_allIn_full_raise', () {
      final player = MockConcretePlayerClass('Alice')..chips = 500;
      final table = Table()
        ..lastBet = 100
        ..minRaiseIncrement = 200;

      table.takeBet(player, BettingMove.allIn);

      expect(table.lastBet, equals(500));
      expect(
        table.minRaiseIncrement,
        equals(400),
        reason: 'All-in for 500 when lastBet was 100 is a raise of 400',
      );
      expect(table.lastRaiseWasFull, isTrue);
    });

    test('test_takeBet_allIn_partial_raise', () {
      final player = MockConcretePlayerClass('Alice')..chips = 250;
      final table = Table()
        ..lastBet = 200
        ..minRaiseIncrement = 200;

      table.takeBet(player, BettingMove.allIn);

      expect(table.lastBet, equals(250));
      expect(
        table.minRaiseIncrement,
        equals(200),
        reason: 'Partial raise should not update minRaiseIncrement',
      );
      expect(table.lastRaiseWasFull, isFalse);
    });

    test('test_takeBet_call_more_than_chips_converts_to_allIn', () {
      final player = MockConcretePlayerClass('Alice')..chips = 500;
      final table = Table()..lastBet = 1000;
      table.takeBet(player, BettingMove.called);
      expect(player.isAllIn, isTrue);
      expect(player.bet, 500);
      expect(player.chips, 0);
      expect(
        table.lastBet,
        1000,
        reason:
            'Table last bet should not decrease because someone went all-in for less',
      );
    });

    test('test_takeBet_raise_more_than_chips_converts_to_allIn', () {
      final player = MockConcretePlayerClass('Alice')..chips = 500;
      final table = Table()
        ..lastBet = 100
        ..raiseAmount = 1000;
      table.takeBet(player, BettingMove.raised);
      expect(player.isAllIn, isTrue);
      expect(player.bet, 500);
      expect(player.chips, 0);
      expect(
        table.lastBet,
        500,
        reason: 'Table last bet should increase to the all-in amount',
      );
    });
  });
}
