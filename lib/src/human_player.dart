import 'player.dart';
import 'betting_move.dart';
import 'terminal_ui.dart';
import 'ansi.dart';

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
          prompt = ' >>> Press [A] to go all-in or [F] to fold.';
        } else {
          validMoves = ['c', 'a', 'f'];
          prompt = ' >>> Press [C] to call $tableLastBet chips, [A] to go all-in, or [F] to fold.';
        }
      } else if (numTimesTableRaised < 4) {
        canAdjust = true;
        if (bet == tableLastBet) {
          validMoves = ['c', 'b', 'f'];
          prompt = ' >>> Use [←]/[→] to adjust bet. Press [C] to check, [B] to bet $customBet chips, or [F] to fold.';
        } else {
          validMoves = ['c', 'r', 'f'];
          prompt = ' >>> Use [←]/[→] to adjust raise. Press [C] to call $tableLastBet chips, [R] to raise to $customBet chips, or [F] to fold.';
        }
      } else {
        validMoves = ['c', 'f'];
        prompt = ' >>> Press [C] to call $tableLastBet chips or [F] to fold.';
      }

      final underlinedPrompt = ansi('\n$prompt\n\n');
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
