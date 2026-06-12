import 'package:test/test.dart';
import 'package:pokerd/src/card.dart';
import 'package:pokerd/src/player.dart';
import 'package:pokerd/src/betting_move.dart';
import 'package:pokerd/src/hand_rank.dart';

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

void main() {
  group('Player', () {
    test('test_init', () {
      final player = MockConcretePlayerClass('John');
      expect(player.name, equals('John'));
    });

    test('test_reset', () {
      const card = Card(CardRank.r2, CardSuite.heart);
      final player = MockConcretePlayerClass('John');
      player.chips = 5000;
      player.isDealer = true;
      player.isBB = true;
      player.isSB = true;
      player.isFolded = true;
      player.isAllIn = true;
      player.isLocked = true;
      player.bet = 300;
      player.hand = [card];
      player.bestHandCards = [card];
      player.bestHandScore = 1000;
      player.bestHandRank = HandRank.highCard;
      player.rankSubtype = 'rank subtype';
      player.kickerCard = card;

      player.reset();

      expect(player.isDealer, isFalse);
      expect(player.isBB, isFalse);
      expect(player.isSB, isFalse);
      expect(player.isFolded, isFalse);
      expect(player.isAllIn, isFalse);
      expect(player.isLocked, isFalse);
      expect(player.bet, equals(0));
      expect(player.hand, isEmpty);
      expect(player.bestHandCards, isEmpty);
      expect(player.bestHandScore, equals(0));
      expect(player.bestHandRank, isNull);
      expect(player.rankSubtype, equals(''));
      expect(player.kickerCard, isNull);

      // These should not change
      expect(player.name, equals('John'));
      expect(player.chips, equals(5000));
    });

    test('test_go_all_in', () {
      final player = MockConcretePlayerClass('John');
      player.chips = 30;
      player.bet = 250;

      player.goAllIn();

      expect(player.chips, equals(0));
      expect(player.bet, equals(280));
      expect(player.isAllIn, isTrue);
    });

    test('test_fold', () {
      final player = MockConcretePlayerClass('John');

      player.fold();

      expect(player.isFolded, isTrue);
    });
  });

  group('PlayerMatchBet', () {
    test('test_match_bet', () {
      final player = MockConcretePlayerClass('John');
      player.chips = 1000;
      player.bet = 250;

      player.matchBet(300);

      expect(player.bet, equals(300));
      expect(player.chips, equals(950));
    });

    test('test_value_error_when_player_left_with_negative_chips', () {
      final player = MockConcretePlayerClass('John');
      player.chips = 5;
      player.bet = 90;

      expect(() => player.matchBet(100), throwsA(isA<ArgumentError>()));
    });

    test(
      'test_value_error_when_amount_to_match_less_than_players_current_bet',
      () {
        final player = MockConcretePlayerClass('John');
        player.chips = 100000;
        player.bet = 500;

        expect(() => player.matchBet(250), throwsA(isA<ArgumentError>()));
      },
    );
  });
}
