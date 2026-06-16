import 'card.dart';
import 'hand_rank.dart';
import 'chips_amount.dart';

abstract class Player {
  final String name;
  ChipsAmount chips = const ChipsAmount(0);
  ChipsAmount bet = const ChipsAmount(0);
  List<Card> hand = [];
  bool isDealer = false;
  bool isBB = false;
  bool isSB = false;
  bool isFolded = false;
  bool isLocked = false;
  bool isAllIn = false;
  bool isInGame = true;
  bool onlyCallOrFold = false;
  List<Card> bestHandCards = [];
  int bestHandScore = 0;
  HandRank? bestHandRank;
  String rankSubtype = '';
  Card? kickerCard;

  Player(this.name);

  void reset() {
    bet = const ChipsAmount(0);
    hand = [];
    isDealer = false;
    isBB = false;
    isSB = false;
    isFolded = false;
    isAllIn = false;
    isLocked = false;
    onlyCallOrFold = false;
    bestHandCards = [];
    bestHandScore = 0;
    bestHandRank = null;
    rankSubtype = '';
    kickerCard = null;
  }

  ChipsAmount matchBet(ChipsAmount amount) {
    if (amount < bet) {
      throw ArgumentError(
        'Player $name made an illegal bet. '
        'Cannot match lesser bet of $amount '
        'since player has already bet $bet.',
      );
    }
    final n = (bet - amount).abs();
    chips -= n;
    bet += n;
    if (chips < const ChipsAmount(0)) {
      throw ArgumentError(
        'Player $name made an illegal bet. '
        'Player left with $chips.',
      );
    }
    return bet;
  }

  void goAllIn() {
    bet += chips;
    chips = const ChipsAmount(0);
    isAllIn = true;
  }

  void fold() {
    isFolded = true;
  }
}
