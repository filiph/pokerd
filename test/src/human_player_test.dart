import 'dart:async';
import 'package:test/test.dart';
import 'package:pokerd/src/terminal_ui.dart';
import 'package:pokerd/src/human_player.dart';
import 'package:pokerd/src/betting_move.dart';

void main() {
  group('HumanPlayer chooseNextMove', () {
    late StreamController<List<int>> streamController;
    late TerminalUI terminalUI;
    late HumanPlayer player;

    setUp(() {
      streamController = StreamController<List<int>>();
      terminalUI = TerminalUI(inputStream: streamController.stream);
      terminalUI.speed = 0; // Disable speed delays for fast test execution
      player = HumanPlayer('Player', terminalUI);
    });

    tearDown(() {
      terminalUI.dispose();
      streamController.close();
    });

    test('can increase and decrease bet using arrow keys', () async {
      player.chips = 1000;
      player.bet = 0;

      final futureMove = player.chooseNextMove(200, 0, 0);

      // Simulate Left arrow (no effect since customBet is at min 200)
      streamController.add([27, 91, 68]); // ESC [ D
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Simulate Right arrow (increase to 300)
      streamController.add([27, 91, 67]); // ESC [ C
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Simulate Right arrow (increase to 400)
      streamController.add([27, 91, 67]); // ESC [ C
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Simulate Left arrow (decrease to 300)
      streamController.add([27, 91, 68]); // ESC [ D
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Simulate 'B' to confirm bet
      streamController.add([98]); // 'b'

      final move = await futureMove;

      expect(move, equals(BettingMove.bet));
      expect(player.customBet, equals(300));
    });

    test('cannot increase bet beyond player max chips', () async {
      player.chips = 250; // max total chips is chips + bet = 250
      player.bet = 0;

      final futureMove = player.chooseNextMove(200, 0, 0);

      // Simulate Right arrow (increase to 250, clamping since next step 300 > 250)
      streamController.add([27, 91, 67]); // ESC [ C
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Simulate Right arrow again (no further effect)
      streamController.add([27, 91, 67]); // ESC [ C
      await Future<void>.delayed(Duration(milliseconds: 10));

      // Simulate 'B' to confirm bet
      streamController.add([98]); // 'b'

      final move = await futureMove;

      expect(move, equals(BettingMove.bet));
      expect(player.customBet, equals(250));
    });
  });
}
