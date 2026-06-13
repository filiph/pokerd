import 'card.dart';
import 'player.dart';
import 'betting_move.dart';
import 'phase.dart';

class Pot {
  int amount;
  List<Player> players;

  Pot(this.amount, this.players);
}

class Table {
  static int increaseBlindHandIncrements = 5;

  int handsPlayed = 0;
  List<Card> community = [];
  List<Pot> pots = [];
  List<int> potTransfers = [];
  int lastBet = 0;
  int bigBlind = 0;
  int raiseAmount = 0;
  int numTimesRaised = 0;

  Table();

  void reset(List<Player> activePlayers) {
    community = [];
    pots = [Pot(0, activePlayers)];
    potTransfers = [];
    lastBet = 0;
    numTimesRaised = 0;
    if (checkIncreaseBigBlind()) {
      bigBlind *= 2;
    }
    raiseAmount = bigBlind;
  }

  bool checkIncreaseBigBlind() {
    return handsPlayed > 0 &&
        handsPlayed % Table.increaseBlindHandIncrements == 0;
  }

  bool takeSmallBlind(Player player) {
    final smallBlind = bigBlind ~/ 2;
    if (player.chips > smallBlind) {
      lastBet = player.matchBet(smallBlind);
      return false;
    } else {
      player.goAllIn();
      potTransfers.add(player.bet);
      potTransfers = potTransfers.toSet().toList();
      if (player.bet > lastBet) {
        lastBet = player.bet;
      }
      return true;
    }
  }

  bool takeBigBlind(Player player) {
    if (player.chips > bigBlind) {
      lastBet = player.matchBet(bigBlind);
      return false;
    } else {
      player.goAllIn();
      potTransfers.add(player.bet);
      potTransfers = potTransfers.toSet().toList();
      if (player.bet > lastBet) {
        lastBet = player.bet;
      }
      return true;
    }
  }

  void takeBet(Player player, BettingMove move) {
    if (move == BettingMove.checked || move == BettingMove.called) {
      lastBet = player.matchBet(lastBet);
    } else if (move == BettingMove.raised || move == BettingMove.bet) {
      numTimesRaised += 1;
      lastBet = player.matchBet(raiseAmount);
    } else if (move == BettingMove.allIn) {
      player.goAllIn();
      potTransfers.add(player.bet);
      // Prevent multiple side pots being created if players go all-in at same amount in same phase
      potTransfers = potTransfers.toSet().toList();
      if (player.bet > lastBet) {
        lastBet = player.bet;
      }
    } else {
      player.fold();
    }
  }

  void updateRaiseAmount(Phase phase) {
    if (phase == Phase.preflop || phase == Phase.flop) {
      raiseAmount = lastBet + bigBlind;
    } else if (phase == Phase.turn || phase == Phase.river) {
      raiseAmount = lastBet + (bigBlind * 2);
    }
  }

  void calculateSidePots(List<Player> activePlayers) {
    if (potTransfers.isNotEmpty) {
      potTransfers.sort();
      final netTransfers = <int>[];
      for (var i = 0; i < potTransfers.length - 1; i++) {
        netTransfers.add(potTransfers[i + 1] - potTransfers[i]);
      }
      netTransfers.insert(0, potTransfers[0]);
      for (var i = 0; i < netTransfers.length; i++) {
        for (final player in activePlayers) {
          if (player.bet == 0) {
            continue;
          }
          if (player.bet < netTransfers[i]) {
            pots.last.amount += player.bet;
            player.bet = 0;
          } else {
            player.bet -= netTransfers[i];
            pots.last.amount += netTransfers[i];
          }
        }
        List<Player> eligiblePlayers;
        if (i == netTransfers.length - 1) {
          eligiblePlayers = [];
          for (final player in activePlayers) {
            if (!player.isFolded && !player.isAllIn) {
              eligiblePlayers.add(player);
            }
          }
        } else {
          eligiblePlayers = [
            for (final player in activePlayers) if (player.bet > 0) player
          ];
        }
        pots.add(Pot(0, eligiblePlayers));
      }
    }
    for (final player in activePlayers) {
      if (player.bet > 0) {
        pots.last.amount += player.bet;
        player.bet = 0;
      }
    }
    potTransfers = [];
  }
}
