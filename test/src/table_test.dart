import 'package:test/test.dart';
import 'package:pokerd/src/card.dart';
import 'package:pokerd/src/player.dart';
import 'package:pokerd/src/betting_move.dart';
import 'package:pokerd/src/table.dart';

class MockConcretePlayerClass extends Player {
  MockConcretePlayerClass(super.name);

  @override
  BettingMove chooseNextMove(
    int tableRaiseAmount,
    int numTimesTableRaised,
    int tableLastBet,
  ) {
    return BettingMove.checked;
  }
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
}
