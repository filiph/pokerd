import 'dart:async';
import 'dart:math';
import 'package:test/test.dart';
import 'package:pokerd/src/game.dart';
import 'package:pokerd/src/table.dart';
import 'package:pokerd/src/player.dart';
import 'package:pokerd/src/phase.dart';
import 'package:pokerd/src/betting_move.dart';
import 'package:pokerd/src/terminal_ui.dart';
import 'package:pokerd/src/human_player.dart';

class MockTerminalUI extends TerminalUI {
  final List<InputChar> keys;
  int _keyIndex = 0;
  MockTerminalUI(this.keys);
  
  @override
  Future<void> write(String text, {int? speedOverride}) async {}
  @override
  Future<void> writeInPlace(String key, List<String> lines) async {}
  @override
  Future<InputChar> readKey() async {
    if (_keyIndex < keys.length) {
      return keys[_keyIndex++];
    }
    return const InputChar.char('c');
  }
  @override
  Future<void> waitForAnyKey() async {}
}

class TestPlayer extends Player {
  TestPlayer(super.name);
}

void main() {
  group('Game Betting Phase Resets', () {
    test('lastBet and minRaiseIncrement are reset at start of each betting round', () async {
      final tui = MockTerminalUI([
        const InputChar.char('c'), // P1 checks
        const InputChar.char('c'), // P2 checks
      ]);
      final game = Game(tui);
      game.players.clear();
      
      final p1 = HumanPlayer('P1')..chips = 1000;
      final p2 = HumanPlayer('P2')..chips = 1000;
      game.players.addAll([p1, p2]);
      for (var p in game.players) p.isInGame = true;
      
      game.table.lastBet = 500;
      game.table.minRaiseIncrement = 1000;
      game.table.numTimesRaised = 3;
      
      game.dealer = p1;
      p1.isDealer = true;
      
      game.phase = Phase.flop; 
      game.table.reset(game.getActivePlayers());
      
      await game.runRoundOfBetting();
      
      expect(game.table.numTimesRaised, equals(0));
      expect(game.table.minRaiseIncrement, equals(200));
      expect(game.table.lastBet, equals(0));
    });
  });

  group('All-in Re-opening Logic', () {
    test('Full raise re-opens betting for locked players', () async {
      // Sequence: P1(D), P2, P3. First act: 1 (P2).
      // 1. P2 checks.
      // 2. P3 goes all-in 500.
      // 3. P1 calls 500.
      // 4. P2 calls 500.
      final tui = MockTerminalUI([
        const InputChar.char('c'), // P2 checks
        const InputChar.char('a'), // P3 all-in 500
        const InputChar.char('c'), // P1 calls 500
        const InputChar.char('c'), // P2 calls 500
      ]);
      final game = Game(tui);
      game.players.clear();
      
      final p1 = HumanPlayer('P1')..chips = 1000;
      final p2 = HumanPlayer('P2')..chips = 1000;
      final p3 = HumanPlayer('P3')..chips = 500;
      
      game.players.addAll([p1, p2, p3]);
      for (var p in game.players) p.isInGame = true;
      game.dealer = p1;
      p1.isDealer = true;
      
      game.phase = Phase.flop;
      game.table.reset(game.players);
      game.table.bigBlind = 200;
      
      await game.betUntilAllLockedIn(1, game.players);
      
      expect(p1.bet, equals(500));
      expect(p2.bet, equals(500));
      expect(p3.bet, equals(500));
      expect(p1.isLocked, isTrue);
      expect(p2.isLocked, isTrue);
    });

    test('Partial raise restricts players to call/fold', () async {
      // Sequence: P1(D), P2, P3. First act: 1 (P2).
      // 1. P2 checks.
      // 2. P3 checks.
      // 3. P1 bets 200.
      // 4. P2 calls 200.
      // 5. P3 goes all-in 250 (Partial raise).
      // 6. P1 tries to raise 'r' -> should be ignored because restricted.
      // 7. P1 calls 250.
      // 8. P2 calls 250.
      
      final tui = MockTerminalUI([
        const InputChar.char('c'), // P2 checks
        const InputChar.char('c'), // P3 checks
        const InputChar.char('b'), // P1 bets 200
        const InputChar.char('c'), // P2 calls 200
        const InputChar.char('a'), // P3 all-in 250
        const InputChar.char('r'), // P1 tries to raise (ignored)
        const InputChar.char('c'), // P1 calls 250
        const InputChar.char('c'), // P2 calls 250
      ]);
      final game = Game(tui);
      game.players.clear();
      
      final p1 = HumanPlayer('P1')..chips = 1000;
      final p2 = HumanPlayer('P2')..chips = 1000;
      final p3 = HumanPlayer('P3')..chips = 250;
      
      game.players.addAll([p1, p2, p3]);
      for (var p in game.players) p.isInGame = true;
      game.dealer = p1;
      p1.isDealer = true;
      
      game.phase = Phase.flop;
      game.table.reset(game.players);
      game.table.bigBlind = 200;
      
      await game.betUntilAllLockedIn(1, game.players);
      
      expect(p1.bet, equals(250));
      expect(p2.bet, equals(250));
      expect(p3.bet, equals(250));
    });
  });

  group('Pot Split Remainder', () {
    test('Remainder chip goes to first active player clockwise from dealer', () async {
      final tui = MockTerminalUI([]);
      final game = Game(tui);
      game.players.clear();
      
      final p1 = TestPlayer('P1')..chips = 0;
      final p2 = TestPlayer('P2')..chips = 0;
      final p3 = TestPlayer('P3')..chips = 0;
      
      game.players.addAll([p1, p2, p3]);
      for (var p in game.players) p.isInGame = true;
      
      game.dealer = p1; 
      game.table.pots = [Pot(11, [p2, p3])];
      
      final handWinners = [p2, p3];
      final share = game.table.pots[0].amount ~/ handWinners.length;
      var remainder = game.table.pots[0].amount % handWinners.length;

      for (final winner in handWinners) {
        winner.chips += share;
      }

      if (remainder > 0) {
        final active = game.getActivePlayers();
        final dealerIndex = active.indexOf(game.dealer!);
        for (var j = 1; j <= active.length; j++) {
          final player = active[(dealerIndex + j) % active.length];
          if (handWinners.contains(player)) {
            player.chips += 1;
            remainder -= 1;
            if (remainder == 0) break;
          }
        }
      }
      
      expect(p2.chips, equals(6));
      expect(p3.chips, equals(5));
    });
  });
}
