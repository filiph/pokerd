import 'dart:async';
import 'package:test/test.dart';
import 'package:pokerd/src/terminal_ui.dart';
import 'package:pokerd/src/human_player.dart';
import 'package:pokerd/src/betting_move.dart';
import 'package:pokerd/src/game.dart';

void main() {
  group('Game.getHumanMove', () {
    late StreamController<List<int>> streamController;
    late TerminalUI terminalUI;
    late Game game;
    late HumanPlayer player;

    setUp(() {
      streamController = StreamController<List<int>>();
      terminalUI = TerminalUI(inputStream: streamController.stream);
      terminalUI.speed = 0; // Disable speed delays for fast test execution
      game = Game(terminalUI);
      player = game.players.firstWhere((p) => p is HumanPlayer) as HumanPlayer;
    });

    tearDown(() {
      terminalUI.dispose();
      streamController.close();
    });

    test('can increase and decrease bet using arrow keys', () async {
      player.chips = 1000;
      player.bet = 0;
      game.table.raiseAmount = 200;

      final futureMove = game.getHumanMove(player);

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
      game.table.raiseAmount = 200;

      final futureMove = game.getHumanMove(player);

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

    test('can choose all-in when normal bet is available', () async {
      player.chips = 1000;
      player.bet = 0;
      game.table.raiseAmount = 200;

      final futureMove = game.getHumanMove(player);

      // Simulate 'A' to go all-in
      streamController.add([97]); // 'a'

      final move = await futureMove;
      expect(move, equals(BettingMove.allIn));
    });

    test('can choose all-in when normal raise is available', () async {
      player.chips = 1000;
      player.bet = 100;
      game.table.raiseAmount = 300;
      game.table.numTimesRaised = 1;
      game.table.lastBet = 200;

      final futureMove = game.getHumanMove(player);

      // Simulate 'A' to go all-in
      streamController.add([97]); // 'a'

      final move = await futureMove;
      expect(move, equals(BettingMove.allIn));
    });

    test('can choose all-in when raised limit of 4 is reached', () async {
      player.chips = 1000;
      player.bet = 100;
      game.table.raiseAmount = 300;
      game.table.numTimesRaised = 4;
      game.table.lastBet = 200;

      final futureMove = game.getHumanMove(player);

      // Simulate 'A' to go all-in
      streamController.add([97]); // 'a'

      final move = await futureMove;
      expect(move, equals(BettingMove.allIn));
    });
  });
}
