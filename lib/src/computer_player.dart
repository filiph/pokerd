import 'dart:math';
import 'player.dart';
import 'betting_move.dart';

enum ComputerPlayingStyle { safe, risky, random }

class ComputerPlayer extends Player {
  final ComputerPlayingStyle playingStyle;
  final Random _random;

  ComputerPlayer(super.name, this.playingStyle, {Random? random})
      : _random = random ?? Random();

  @override
  Future<BettingMove> chooseNextMove(
    int tableRaiseAmount,
    int numTimesTableRaised,
    int tableLastBet,
  ) async {
    switch (playingStyle) {
      case ComputerPlayingStyle.safe:
        return _safePlay(tableRaiseAmount, numTimesTableRaised, tableLastBet);
      case ComputerPlayingStyle.risky:
        return _riskyPlay(tableRaiseAmount, numTimesTableRaised, tableLastBet);
      case ComputerPlayingStyle.random:
        return _randomPlay(tableRaiseAmount, numTimesTableRaised, tableLastBet);
    }
  }

  BettingMove _riskyPlay(
    int tableRaiseAmount,
    int numTimesTableRaised,
    int tableLastBet,
  ) {
    final x = _random.nextDouble();
    if (chips <= (bet - tableRaiseAmount).abs()) {
      if (chips <= (bet - tableLastBet).abs()) {
        if (x <= 0.90) {
          return BettingMove.allIn;
        } else {
          return BettingMove.folded;
        }
      } else {
        if (x <= 0.40) {
          if (bet == tableLastBet) {
            return BettingMove.checked;
          } else {
            return BettingMove.called;
          }
        } else if (x <= 0.90) {
          return BettingMove.allIn;
        } else {
          return BettingMove.folded;
        }
      }
    } else if (numTimesTableRaised < 4) {
      if (bet == tableLastBet) {
        if (x <= 0.05) {
          return BettingMove.allIn;
        } else if (x <= 0.45) {
          return BettingMove.checked;
        } else if (x <= 0.90) {
          return BettingMove.bet;
        } else {
          return BettingMove.folded;
        }
      } else {
        if (x <= 0.05) {
          return BettingMove.allIn;
        } else if (x <= 0.45) {
          return BettingMove.called;
        } else if (x <= 0.90) {
          return BettingMove.raised;
        } else {
          return BettingMove.folded;
        }
      }
    } else {
      if (x <= 0.05) {
        return BettingMove.allIn;
      } else if (x <= 0.90) {
        return BettingMove.called;
      } else {
        return BettingMove.folded;
      }
    }
  }

  BettingMove _safePlay(
    int tableRaiseAmount,
    int numTimesTableRaised,
    int tableLastBet,
  ) {
    final x = _random.nextDouble();
    if (chips <= (bet - tableRaiseAmount).abs()) {
      if (chips <= (bet - tableLastBet).abs()) {
        if (x <= 0.60) {
          return BettingMove.allIn;
        } else {
          return BettingMove.folded;
        }
      } else {
        if (x <= 0.60) {
          if (bet == tableLastBet) {
            return BettingMove.checked;
          } else {
            return BettingMove.called;
          }
        } else if (x <= 0.80) {
          return BettingMove.allIn;
        } else {
          return BettingMove.folded;
        }
      }
    } else if (numTimesTableRaised < 4) {
      if (bet == tableLastBet) {
        if (x <= 0.02) {
          return BettingMove.allIn;
        } else if (x <= 0.72) {
          return BettingMove.checked;
        } else if (x <= 0.90) {
          return BettingMove.bet;
        } else {
          return BettingMove.folded;
        }
      } else {
        if (x <= 0.02) {
          return BettingMove.allIn;
        } else if (x <= 0.72) {
          return BettingMove.called;
        } else if (x <= 0.90) {
          return BettingMove.raised;
        } else {
          return BettingMove.folded;
        }
      }
    } else {
      if (x <= 0.02) {
        return BettingMove.allIn;
      } else if (x <= 0.90) {
        return BettingMove.called;
      } else {
        return BettingMove.folded;
      }
    }
  }

  BettingMove _randomPlay(
    int tableRaiseAmount,
    int numTimesTableRaised,
    int tableLastBet,
  ) {
    final x = _random.nextDouble();
    if (chips <= (bet - tableRaiseAmount).abs()) {
      if (chips <= (bet - tableLastBet).abs()) {
        if (x <= 0.50) {
          return BettingMove.allIn;
        } else {
          return BettingMove.folded;
        }
      } else {
        if (x <= 0.30) {
          if (bet == tableLastBet) {
            return BettingMove.checked;
          } else {
            return BettingMove.called;
          }
        } else if (x <= 0.66) {
          return BettingMove.allIn;
        } else {
          return BettingMove.folded;
        }
      }
    } else if (numTimesTableRaised < 4) {
      if (bet == tableLastBet) {
        if (x <= 0.05) {
          return BettingMove.allIn;
        } else if (x <= 0.38) {
          return BettingMove.checked;
        } else if (x <= 0.66) {
          return BettingMove.bet;
        } else {
          return BettingMove.folded;
        }
      } else {
        if (x <= 0.05) {
          return BettingMove.allIn;
        } else if (x <= 0.38) {
          return BettingMove.called;
        } else if (x <= 0.66) {
          return BettingMove.raised;
        } else {
          return BettingMove.folded;
        }
      }
    } else {
      if (x <= 0.05) {
        return BettingMove.allIn;
      } else if (x <= 0.66) {
        return BettingMove.called;
      } else {
        return BettingMove.folded;
      }
    }
  }
}
