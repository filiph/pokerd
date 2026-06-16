import 'player.dart';
import 'chips_amount.dart';

class HumanPlayer extends Player {
  ChipsAmount customBet = const ChipsAmount(0);

  HumanPlayer(super.name);
}
