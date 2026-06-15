import 'ansi.dart';
import 'betting_move.dart';
import 'player.dart';
import 'terminal_ui.dart';

class HumanPlayer extends Player {
  final TerminalUI tui;
  int customBet = 0;

  HumanPlayer(super.name, this.tui);

  @override
  Future<BettingMove> chooseNextMove(
    int tableRaiseAmount,
    int numTimesTableRaised,
    int tableLastBet,
  ) async {
    customBet = tableRaiseAmount;

    while (true) {
      List<String> validMoves;
      String prompt;
      bool canAdjust = false;

      // If player doesn't have enough chips to raise or if player has just enough chips to raise
      if (chips <= (bet - tableRaiseAmount).abs()) {
        // If not enough chips to call
        if (chips <= (bet - tableLastBet).abs()) {
          validMoves = ['f', 'a'];
          prompt = '> [A]ll-in   [F]old';
        } else {
          validMoves = ['c', 'a', 'f'];
          prompt = '> [C]all $tableLastBet chips  [A]ll-in   [F]old';
        }
      } else if (numTimesTableRaised < 4) {
        canAdjust = true;
        if (bet == tableLastBet) {
          validMoves = ['c', 'b', 'a', 'f'];
          prompt =
              '> [C]heck   [B]et [←]$customBet[→] chips   [A]ll-in   [F]old';
        } else {
          validMoves = ['c', 'r', 'a', 'f'];
          prompt =
              '> [C]all $tableLastBet chips   [R]aise to [←]$customBet[→] chips   [A]ll-in   [F]old';
        }
      } else {
        validMoves = ['c', 'a', 'f'];
        prompt = '> [C]all $tableLastBet chips   [A]ll-in   [F]old';
      }

      final underlinedPrompt = ansi('\n$prompt');
      final linesToPrint = underlinedPrompt.split('\n');
      await tui.writeInPlace('human_prompt', linesToPrint);

      final key = await tui.readKey();
      if (key.isLeft && canAdjust) {
        if (customBet > tableRaiseAmount) {
          if (customBet - 100 >= tableRaiseAmount) {
            customBet -= 100;
          } else {
            customBet = tableRaiseAmount;
          }
        }
      } else if (key.isRight && canAdjust) {
        final maxBet = chips + bet;
        if (customBet < maxBet) {
          if (customBet + 100 <= maxBet) {
            customBet += 100;
          } else {
            customBet = maxBet;
          }
        }
      } else {
        final char = key.char?.toLowerCase();
        if (char != null && validMoves.contains(char)) {
          if (char == 'b') {
            return BettingMove.bet;
          } else if (char == 'r') {
            return BettingMove.raised;
          } else if (char == 'f') {
            return BettingMove.folded;
          } else if (char == 'a') {
            return BettingMove.allIn;
          } else if (bet == tableLastBet) {
            return BettingMove.checked;
          } else {
            return BettingMove.called;
          }
        }
      }
    }
  }
}
