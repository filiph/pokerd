import 'card.dart';
import 'player.dart';

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
}
