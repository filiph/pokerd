import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:pokerd/src/game.dart';
import 'package:pokerd/src/game_event.dart';
import 'package:pokerd/src/terminal_ui.dart';
import 'package:pokerd/src/computer_player.dart';
import 'package:pokerd/src/chips_amount.dart';
import 'package:pokerd/src/human_player.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('tournaments',
        abbr: 't',
        help: 'How many tournaments should be played',
        defaultsTo: '1')
    ..addOption('max-rounds',
        abbr: 'r',
        help: 'How many rounds per tournament should be played',
        defaultsTo: '100')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help');

  final results = parser.parse(args);

  if (results['help'] as bool || args.isEmpty) {
    print('Usage: dart tool/self_play.dart [arguments]');
    print(parser.usage);
    return;
  }

  final tournaments = int.parse(results['tournaments'] as String);
  final maxRounds = int.parse(results['max-rounds'] as String);

  final stats = <String, PlayerStats>{};

  for (var i = 0; i < tournaments; i++) {
    await runTournament(maxRounds, stats);
  }

  for (final entry in stats.entries) {
    print(jsonEncode({
      'statsFor': entry.key,
      ...entry.value.toJson(),
    }));
  }
}

class PlayerStats {
  int totalGames = 0;
  int totalGamesActive = 0;
  int wins = 0;

  void recordGame() => totalGames++;
  void recordActive() => totalGamesActive++;
  void recordWin() => wins++;

  Map<String, dynamic> toJson() => {
        'totalGames': totalGames,
        'totalGamesActive': totalGamesActive,
        'wins': wins,
      };
}

class NullStringSink implements StringSink {
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = ""]) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = ""]) {}
}

class SilentTUI extends TerminalUI {
  SilentTUI()
      : super(
            inputStream: const Stream<List<int>>.empty(),
            outputSink: NullStringSink());

  @override
  Future<InputChar> readKey() async {
    return const InputChar.char('q');
  }
}

Future<void> runTournament(
    int maxRounds, Map<String, PlayerStats> allStats) async {
  final eventController = StreamController<GameEvent>();

  final tui = SilentTUI();
  final game = Game(tui, eventController: eventController);

  // Use only computer players
  game.players.removeWhere((p) => p is HumanPlayer);
  for (final player in game.players) {
    allStats.putIfAbsent(player.name, () => PlayerStats());
  }

  final sub = eventController.stream.listen((event) {
    print(jsonEncode(event.toJson()));

    if (event.event == 'roundStart') {
      final activePlayers = (event.data['players'] as List).cast<String>();
      for (final name in activePlayers) {
        allStats[name]?.recordActive();
      }
      for (final name in allStats.keys) {
        allStats[name]?.recordGame();
      }
    } else if (event.event == 'win') {
      final winner = event.data['player'] as String;
      allStats[winner]?.recordWin();
    }
  });

  await game.play(maxRounds: maxRounds);
  await sub.cancel();
  await eventController.close();
}
