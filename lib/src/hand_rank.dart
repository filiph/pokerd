import 'package:meta/meta.dart';

import 'card.dart';
import 'player.dart';

part 'hand_rank_types.dart';

sealed class HandRank implements Comparable<HandRank> {
  static const HighCard highCard = HighCard();

  static const OnePair onePair = OnePair();

  static const TwoPair twoPair = TwoPair();

  static const ThreeOfAKind threeOfAKind = ThreeOfAKind();

  static const Straight straight = Straight();

  static const Flush flush = Flush();

  static const FullHouse fullHouse = FullHouse();

  static const FourOfAKind fourOfAKind = FourOfAKind();

  static const StraightFlush straightFlush = StraightFlush();

  static const RoyalFlush royalFlush = RoyalFlush();

  static const WheelStraight wheelStraight = WheelStraight();

  static const WheelStraightFlush wheelStraightFlush = WheelStraightFlush();

  static const List<HandRank> values = [
    highCard,
    onePair,
    twoPair,
    threeOfAKind,
    straight,
    flush,
    fullHouse,
    fourOfAKind,
    straightFlush,
    royalFlush,
  ];

  static const Map<int, String> _cardIntStrDict = {
    2: 'Two',
    3: 'Three',
    4: 'Four',
    5: 'Five',
    6: 'Six',
    7: 'Seven',
    8: 'Eight',
    9: 'Nine',
    10: 'Ten',
    11: 'Jack',
    12: 'Queen',
    13: 'King',
    14: 'Ace',
  };

  final int value;

  final String description;

  const HandRank(this.value, this.description);

  @override
  int get hashCode => value.hashCode;

  bool operator <(HandRank other) => value < other.value;

  bool operator <=(HandRank other) => value <= other.value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is HandRank && value == other.value);
  }

  bool operator >(HandRank other) => value > other.value;

  bool operator >=(HandRank other) => value >= other.value;

  @override
  int compareTo(HandRank other) => value.compareTo(other.value);

  @override
  String toString() => description;

  @visibleForTesting
  static void assignHandrankSubtypes(List<Player> showdownPlayers) {
    for (final player in showdownPlayers) {
      final score = player.bestHandScore;
      final handRank = player.bestHandRank;
      if (handRank == null) continue;
      final scoreStr = score.toString();

      switch (handRank) {
        case StraightFlush() || Straight():
          final highCardVal = int.parse(scoreStr.substring(1, 3));
          final highCard = _cardIntStrDict[highCardVal];
          player.rankSubtype = ': $highCard high';
        case FullHouse():
          final tripletVal = int.parse(scoreStr.substring(1, 3));
          final pairVal = int.parse(scoreStr.substring(3, 5));
          final tripletCard = _cardIntStrDict[tripletVal];
          final pairCard = _cardIntStrDict[pairVal];
          final tripletStr = tripletCard == 'Six' ? 'Sixes' : '${tripletCard}s';
          final pairStr = pairCard == 'Six' ? 'Sixes' : '${pairCard}s';
          player.rankSubtype = ': $tripletStr over $pairStr';
        case TwoPair():
          final higherVal = int.parse(scoreStr.substring(1, 3));
          final lowerVal = int.parse(scoreStr.substring(3, 5));
          final higherPair = _cardIntStrDict[higherVal];
          final lowerPair = _cardIntStrDict[lowerVal];
          final higherStr = higherPair == 'Six' ? 'Sixes' : '${higherPair}s';
          final lowerStr = lowerPair == 'Six' ? 'Sixes' : '${lowerPair}s';
          player.rankSubtype = ': $higherStr and $lowerStr';
        case OnePair():
          final pairVal = int.parse(scoreStr.substring(1, 3));
          final pairCard = _cardIntStrDict[pairVal];
          final pairStr = pairCard == 'Six' ? 'Sixes' : '${pairCard}s';
          player.rankSubtype = ': $pairStr';
        case FourOfAKind() || ThreeOfAKind():
          final tupleVal = int.parse(scoreStr.substring(1, 3));
          final tupleCard = _cardIntStrDict[tupleVal];
          final tupleStr = tupleCard == 'Six' ? 'Sixes' : '${tupleCard}s';
          player.rankSubtype = ': $tupleStr';
        case HighCard():
          final highCardVal = int.parse(scoreStr.substring(1, 3));
          final highCard = _cardIntStrDict[highCardVal];
          player.rankSubtype = ': $highCard';
        case RoyalFlush() || Flush():
          break;
      }
    }
  }

  static List<Player> determineShowdownWinner(
    List<Player> showdownPlayers,
    List<Card> community,
  ) {
    var winners = <Player>[];
    for (final player in showdownPlayers) {
      final allCards = [...player.hand, ...community];
      final combos = getCombinations(allCards, 5);
      for (final combo in combos) {
        final rawScore = scoreHand(combo);
        if (rawScore > player.bestHandScore) {
          player.bestHandScore = rawScore;
          final sortedCombo = List<Card>.from(combo)
            ..sort((a, b) => b.rank.rank.compareTo(a.rank.rank));
          player.bestHandCards = sortedCombo;
        }
      }
      player.bestHandRank = HandRank.fromScore(player.bestHandScore);
      if (winners.isEmpty) {
        winners = [player];
      } else if (player.bestHandScore > winners[0].bestHandScore) {
        winners = [player];
      } else if (player.bestHandScore == winners[0].bestHandScore) {
        winners.add(player);
      }
    }
    assignHandrankSubtypes(showdownPlayers);
    _assignKickerCard(winners, showdownPlayers);
    return winners;
  }

  static HandRank fromScore(int score) {
    if (score == 50500000000) {
      return wheelStraight;
    }
    if (score == 90500000000) {
      return wheelStraightFlush;
    }
    final leadingDigit = score ~/ 10000000000;
    return fromValue(leadingDigit);
  }

  static HandRank fromValue(int val) {
    for (final rank in values) {
      if (rank.value == val) return rank;
    }
    throw ArgumentError('Unknown hand rank value: $val');
  }

  @visibleForTesting
  static List<List<T>> getCombinations<T>(List<T> list, int k) {
    final result = <List<T>>[];
    void helper(int start, List<T> current) {
      if (current.length == k) {
        result.add(List<T>.from(current));
        return;
      }
      for (var i = start; i < list.length; i++) {
        current.add(list[i]);
        helper(i + 1, current);
        current.removeLast();
      }
    }

    helper(0, []);
    return result;
  }

  static int scoreHand(List<Card> hand) {
    final sortedHand = List<Card>.from(hand)
      ..sort((a, b) => b.rank.rank.compareTo(a.rank.rank));

    var score = _scoreRoyalFlush(sortedHand);
    if (score != 0) return score;

    score = _scoreStraightFlush(sortedHand);
    if (score != 0) return score;

    score = _scoreNumOfKind(sortedHand, 4);
    if (score != 0) return score;

    score = _scoreFullHouse(sortedHand);
    if (score != 0) return score;

    score = _scoreFlush(sortedHand);
    if (score != 0) return score;

    score = _scoreStraight(sortedHand);
    if (score != 0) return score;

    score = _scoreNumOfKind(sortedHand, 3);
    if (score != 0) return score;

    score = _scoreTwoPair(sortedHand);
    if (score != 0) return score;

    score = _scoreNumOfKind(sortedHand, 2);
    if (score != 0) return score;

    return _scoreHighCard(sortedHand);
  }

  static void _assignKickerCard(
    List<Player> winners,
    List<Player> showdownPlayers,
  ) {
    if (winners.isEmpty) return;
    int? kickerCardRank;
    final firstWinnerRank = winners[0].bestHandRank;
    if (firstWinnerRank == null) return;

    switch (firstWinnerRank) {
      case HighCard() || OnePair() || ThreeOfAKind() || FourOfAKind():
        final winnerScoreStr = winners[0].bestHandScore.toString();
        final targetPrefix = winnerScoreStr.substring(0, 3);
        final tiedPlayers = showdownPlayers
            .where(
              (player) =>
                  player.bestHandScore.toString().startsWith(targetPrefix),
            )
            .toList();

        if (tiedPlayers.length == 1) return;

        for (var i = 3; i < 11; i += 2) {
          final cardValues = tiedPlayers.map((player) {
            final scoreStr = player.bestHandScore.toString();
            return int.parse(scoreStr.substring(i, i + 2));
          }).toList();
          final maxVal = cardValues.reduce((a, b) => a > b ? a : b);
          final countMax = cardValues.where((v) => v == maxVal).length;
          if (countMax != tiedPlayers.length) {
            kickerCardRank = maxVal;
            break;
          }
        }

      case TwoPair():
        final winnerScoreStr = winners[0].bestHandScore.toString();
        final targetPrefix = winnerScoreStr.substring(0, 5);
        final tiedPlayers = showdownPlayers
            .where(
              (player) =>
                  player.bestHandScore.toString().startsWith(targetPrefix),
            )
            .toList();

        if (tiedPlayers.length == 1) return;

        final playersLastCardList = tiedPlayers.map((player) {
          final scoreStr = player.bestHandScore.toString();
          return int.parse(scoreStr.substring(5, 7));
        }).toList();
        final maxVal = playersLastCardList.reduce((a, b) => a > b ? a : b);
        final countMax = playersLastCardList.where((v) => v == maxVal).length;
        if (countMax != tiedPlayers.length) {
          kickerCardRank = maxVal;
        }

      case Flush():
        final winnerScoreStr = winners[0].bestHandScore.toString();
        final targetPrefix = winnerScoreStr.substring(0, 1);
        final tiedPlayers = showdownPlayers
            .where(
              (player) =>
                  player.bestHandScore.toString().startsWith(targetPrefix),
            )
            .toList();

        if (tiedPlayers.length == 1) return;

        for (var i = 1; i < 11; i += 2) {
          final cardValues = tiedPlayers.map((player) {
            final scoreStr = player.bestHandScore.toString();
            return int.parse(scoreStr.substring(i, i + 2));
          }).toList();
          final maxVal = cardValues.reduce((a, b) => a > b ? a : b);
          final countMax = cardValues.where((v) => v == maxVal).length;
          if (countMax != tiedPlayers.length) {
            kickerCardRank = maxVal;
            break;
          }
        }

      case Straight() || FullHouse() || StraightFlush() || RoyalFlush():
        break;
    }

    if (kickerCardRank != null) {
      for (final winner in winners) {
        for (final card in winner.bestHandCards) {
          if (card.rank.rank == kickerCardRank) {
            winner.kickerCard = card;
            break;
          }
        }
      }
    }
  }

  static int _scoreFlush(List<Card> hand) {
    final suitValues = hand.map((c) => c.suite).toSet();
    if (suitValues.length == 1) {
      final rankValues = hand.map((c) => c.rank.rank).toList();
      final buffer = StringBuffer('6');
      for (final r in rankValues) {
        buffer.write(r.toString().padLeft(2, '0'));
      }
      return int.parse(buffer.toString());
    }
    return 0;
  }

  static int _scoreFullHouse(List<Card> hand) {
    final rankValues = hand.map((c) => c.rank.rank).toList();
    final uniqueValues = rankValues.toSet().toList();
    if (uniqueValues.length == 2) {
      final count0 = rankValues.where((v) => v == uniqueValues[0]).length;
      final count1 = rankValues.where((v) => v == uniqueValues[1]).length;
      if ((count0 == 3 && count1 == 2) || (count0 == 2 && count1 == 3)) {
        final int tripletValue;
        final int pairValue;
        if (rankValues.where((v) => v == rankValues[0]).length == 3) {
          tripletValue = rankValues[0];
          pairValue = rankValues[4];
        } else {
          pairValue = rankValues[0];
          tripletValue = rankValues[4];
        }
        final buffer = StringBuffer('7')
          ..write(tripletValue.toString().padLeft(2, '0'))
          ..write(pairValue.toString().padLeft(2, '0'))
          ..write('000000');
        return int.parse(buffer.toString());
      }
    }
    return 0;
  }

  static int _scoreHighCard(List<Card> hand) {
    final buffer = StringBuffer('1');
    for (final card in hand) {
      buffer.write(card.rank.rank.toString().padLeft(2, '0'));
    }
    return int.parse(buffer.toString());
  }

  static int _scoreNumOfKind(List<Card> hand, int n) {
    final rankValues = hand.map((c) => c.rank.rank).toList();
    for (final value in rankValues) {
      final count = rankValues.where((v) => v == value).length;
      if (count == n) {
        final tupleValue = value;
        if (n == 4) {
          final nontupleValue = rankValues
              .where((x) => x != tupleValue)
              .toList();
          final buffer = StringBuffer('8')
            ..write(tupleValue.toString().padLeft(2, '0'))
            ..write(nontupleValue[0].toString().padLeft(2, '0'))
            ..write('000000');
          return int.parse(buffer.toString());
        }
        if (n == 3) {
          final nontupleValues =
              rankValues.where((x) => x != tupleValue).toList()
                ..sort((a, b) => b.compareTo(a));
          final buffer = StringBuffer('4')
            ..write(tupleValue.toString().padLeft(2, '0'))
            ..write(nontupleValues[0].toString().padLeft(2, '0'))
            ..write(nontupleValues[1].toString().padLeft(2, '0'))
            ..write('0000');
          return int.parse(buffer.toString());
        }
        if (n == 2) {
          final nontupleValues =
              rankValues.where((x) => x != tupleValue).toList()
                ..sort((a, b) => b.compareTo(a));
          final buffer = StringBuffer('2')
            ..write(tupleValue.toString().padLeft(2, '0'))
            ..write(nontupleValues[0].toString().padLeft(2, '0'))
            ..write(nontupleValues[1].toString().padLeft(2, '0'))
            ..write(nontupleValues[2].toString().padLeft(2, '0'))
            ..write('00');
          return int.parse(buffer.toString());
        }
      }
    }
    return 0;
  }

  static int _scoreRoyalFlush(List<Card> hand) {
    if (_scoreStraightFlush(hand) != 0) {
      final rankValues = hand.map((c) => c.rank.rank).toList();
      if (rankValues[0] == 14 &&
          rankValues[1] == 13 &&
          rankValues[2] == 12 &&
          rankValues[3] == 11 &&
          rankValues[4] == 10) {
        return 100000000000;
      }
    }
    return 0;
  }

  static int _scoreStraight(List<Card> hand) {
    final rankValues = hand.map((c) => c.rank.rank).toList();
    final maxRank = rankValues.reduce((a, b) => a > b ? a : b);
    final minRank = rankValues.reduce((a, b) => a < b ? a : b);
    final uniqueCount = rankValues.toSet().length;

    if ((maxRank - minRank == 4) && uniqueCount == 5) {
      final buffer = StringBuffer('5')
        ..write(maxRank.toString().padLeft(2, '0'))
        ..write('00000000');
      return int.parse(buffer.toString());
    }

    if (uniqueCount == 5 &&
        rankValues.contains(14) &&
        rankValues.contains(5) &&
        rankValues.contains(4) &&
        rankValues.contains(3) &&
        rankValues.contains(2)) {
      final buffer = StringBuffer('5')..write('0500000000');
      return int.parse(buffer.toString());
    }

    return 0;
  }

  static int _scoreStraightFlush(List<Card> hand) {
    final flushScore = _scoreFlush(hand);
    final straightScore = _scoreStraight(hand);
    if (flushScore != 0 && straightScore != 0) {
      return 90000000000 + (straightScore - 50000000000);
    }
    return 0;
  }

  static int _scoreTwoPair(List<Card> hand) {
    final rankValues = hand.map((c) => c.rank.rank).toList();
    final v1 = rankValues[1];
    final v3 = rankValues[3];
    final countV1 = rankValues.where((v) => v == v1).length;
    final countV3 = rankValues.where((v) => v == v3).length;

    if (countV1 == 2 && countV3 == 2) {
      final pairedValues = [v1, v3]..sort((a, b) => b.compareTo(a));
      final unpairedValue = rankValues.firstWhere((v) => v != v1 && v != v3);
      final buffer = StringBuffer('3')
        ..write(pairedValues[0].toString().padLeft(2, '0'))
        ..write(pairedValues[1].toString().padLeft(2, '0'))
        ..write(unpairedValue.toString().padLeft(2, '0'))
        ..write('0000');
      return int.parse(buffer.toString());
    }
    return 0;
  }
}
