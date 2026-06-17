import 'dart:math';

import 'betting_move.dart';
import 'card.dart';
import 'hand_rank.dart';
import 'player.dart';

import 'package:pokerd/src/chips_amount.dart';

enum ComputerPlayingStyle { grandma, leeroy, suitcase, michelle }

class ComputerPlayer extends Player {
  final ComputerPlayingStyle playingStyle;
  final double error;
  final int monteCarloIterations;
  final Random _random;

  double lastWinProb = 0.0;

  ComputerPlayer(
    super.name,
    this.playingStyle, {
    this.error = 0.0,
    required this.monteCarloIterations,
    Random? random,
  }) : _random = random ?? Random();

  static List<ComputerPlayer> createDefaultPlayers() => [
        ComputerPlayer('Grandma', ComputerPlayingStyle.grandma,
            monteCarloIterations: 300),
        ComputerPlayer('Kyle', ComputerPlayingStyle.leeroy,
            monteCarloIterations: 100),
        ComputerPlayer('Mr. Suitcase', ComputerPlayingStyle.suitcase,
            monteCarloIterations: 500),
        ComputerPlayer('Michelle', ComputerPlayingStyle.michelle,
            monteCarloIterations: 400),
      ];

  Future<BettingMove> chooseNextMove(
    ChipsAmount tableRaiseAmount,
    int numTimesTableRaised,
    ChipsAmount tableLastBet, {
    List<Card> community = const [],
    ChipsAmount potSize = const ChipsAmount(0),
    List<ChipsAmount> otherBets = const [],
  }) async {
    final numOpponents = otherBets.length;
    var winProb = HandRank.estimateWinProbability(
      hand,
      community,
      numOpponents,
      iterations: monteCarloIterations,
    );

    // Apply error jitter
    if (error > 0) {
      final jitter = (_random.nextDouble() * 2 - 1) * error;
      winProb = (winProb + jitter).clamp(0.0, 1.0);
    }
    lastWinProb = winProb;

    final move = switch (playingStyle) {
      ComputerPlayingStyle.grandma => _grandmaPlay(
        winProb,
        tableRaiseAmount,
        numTimesTableRaised,
        tableLastBet,
      ),
      ComputerPlayingStyle.leeroy => _leeroyPlay(
        winProb,
        tableRaiseAmount,
        numTimesTableRaised,
        tableLastBet,
      ),
      ComputerPlayingStyle.suitcase => _suitcasePlay(
        winProb,
        tableRaiseAmount,
        numTimesTableRaised,
        tableLastBet,
        potSize,
      ),
      ComputerPlayingStyle.michelle => _michellePlay(
        winProb,
        tableRaiseAmount,
        numTimesTableRaised,
        tableLastBet,
        potSize,
        otherBets,
      ),
    };

    // Safety check: if we chose a move we can't afford, go all-in.
    if (move == BettingMove.called ||
        move == BettingMove.raised ||
        move == BettingMove.bet) {
      final targetBet = (move == BettingMove.called)
          ? tableLastBet
          : tableRaiseAmount;
      if (targetBet - bet > chips) {
        return BettingMove.allIn;
      }
    }

    return move;
  }

  BettingMove _grandmaPlay(
    double winProb,
    ChipsAmount tableRaiseAmount,
    int numTimesTableRaised,
    ChipsAmount tableLastBet,
  ) {
    // Grandma is very conservative.
    if (winProb > 0.5) {
      if (bet < tableLastBet) {
        return BettingMove.called;
      } else if (numTimesTableRaised < 3) {
        return (bet == tableLastBet) ? BettingMove.bet : BettingMove.raised;
      }
      return (bet == tableLastBet) ? BettingMove.checked : BettingMove.called;
    } else if (winProb > 0.2) {
      if (bet == tableLastBet) {
        return BettingMove.checked;
      } else if ((tableLastBet.value - bet.value) < chips.value * 0.1) {
        // Only call if it's cheap
        return BettingMove.called;
      }
    }
    return (bet == tableLastBet) ? BettingMove.checked : BettingMove.folded;
  }

  BettingMove _leeroyPlay(
    double winProb,
    ChipsAmount tableRaiseAmount,
    int numTimesTableRaised,
    ChipsAmount tableLastBet,
  ) {
    // Leeroy is overconfident and aggressive.
    final overconfidence = 0.2;
    final effectiveWinProb = (winProb + overconfidence).clamp(0.0, 1.0);

    if (effectiveWinProb > 0.5) {
      if (numTimesTableRaised < 4) {
        return (bet == tableLastBet) ? BettingMove.bet : BettingMove.raised;
      }
      return BettingMove.allIn;
    } else if (effectiveWinProb > 0.2) {
      return (bet == tableLastBet) ? BettingMove.checked : BettingMove.called;
    } else {
      // Even with low prob, he might stay in
      if (_random.nextDouble() < 0.3) {
        return (bet == tableLastBet) ? BettingMove.checked : BettingMove.called;
      }
    }
    return (bet == tableLastBet) ? BettingMove.checked : BettingMove.folded;
  }

  BettingMove _suitcasePlay(
    double winProb,
    ChipsAmount tableRaiseAmount,
    int numTimesTableRaised,
    ChipsAmount tableLastBet,
    ChipsAmount potSize,
  ) {
    // Suitcase uses pure pot odds.
    final callAmount = tableLastBet.value - bet.value;
    if (callAmount <= 0) {
      if (winProb > 0.6 && numTimesTableRaised < 3) {
        return BettingMove.bet;
      }
      return BettingMove.checked;
    }

    final effectiveCallAmount = min(callAmount, chips.value);
    final potOdds = effectiveCallAmount / (potSize.value + effectiveCallAmount);
    if (winProb > potOdds) {
      if (winProb > potOdds * 1.5 && numTimesTableRaised < 3) {
        return BettingMove.raised;
      }
      return BettingMove.called;
    }

    return BettingMove.folded;
  }

  BettingMove _michellePlay(
    double winProb,
    ChipsAmount tableRaiseAmount,
    int numTimesTableRaised,
    ChipsAmount tableLastBet,
    ChipsAmount potSize,
    List<ChipsAmount> otherBets,
  ) {
    // Michelle is well-rounded.
    final callAmount = tableLastBet.value - bet.value;
    if (callAmount <= 0) {
      if (winProb > 0.5 && numTimesTableRaised < 3) {
        return BettingMove.bet;
      }
      return BettingMove.checked;
    }

    final effectiveCallAmount = min(callAmount, chips.value);
    final potOdds = effectiveCallAmount / (potSize.value + effectiveCallAmount);

    // Consider others' bets as signal
    var othersConfidence = 0.0;
    if (otherBets.isNotEmpty) {
      final maxOtherBet = otherBets.map((b) => b.value).reduce(max);
      if (maxOtherBet > tableLastBet.value) {
        // Someone raised even more?
      }
      // Simple heuristic: if avg bet is high relative to pot, they are confident
      final avgOtherBet =
          otherBets.map((b) => b.value).reduce((a, b) => a + b) /
              otherBets.length;
      othersConfidence = (avgOtherBet / (potSize.value + 1)).clamp(0.0, 1.0);
    }

    final adjustedWinProb = winProb * (1.0 - othersConfidence * 0.12);

    if (adjustedWinProb > potOdds) {
      if (adjustedWinProb > potOdds * 1.22 && numTimesTableRaised < 3) {
        return BettingMove.raised;
      }
      return BettingMove.called;
    }

    return BettingMove.folded;
  }
}
