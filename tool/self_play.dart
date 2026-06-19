import 'dart:async';
import 'dart:convert';

import 'package:args/args.dart';
import 'package:pokerd/src/game.dart';
import 'package:pokerd/src/game_event.dart';
import 'package:pokerd/src/human_player.dart';
import 'package:pokerd/src/terminal_ui.dart';
import 'package:pokerd/src/computer_player.dart';
import 'package:pokerd/src/betting_move.dart';
import 'package:pokerd/src/chips_amount.dart';
import 'package:pokerd/src/card.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'tournaments',
      abbr: 't',
      help: 'How many tournaments should be played',
      defaultsTo: '1',
    )
    ..addOption(
      'max-rounds',
      abbr: 'r',
      help: 'How many rounds per tournament should be played',
      defaultsTo: '100',
    )
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
    print(jsonEncode({'statsFor': entry.key, ...entry.value.toJson()}));
  }
}

class PlayerStats {
  int totalGames = 0;
  int totalGamesActive = 0;
  int wins = 0;

  int foldsPreflop = 0;
  int foldsFlop = 0;
  int foldsTurn = 0;
  int foldsRiver = 0;

  double totalWinProbAtFold = 0;
  double totalWinProbAtAction = 0;
  double totalPotOddsAtFold = 0;
  double totalPotOddsAtAction = 0;

  int totalActions = 0;

  final Map<String, int> beats = {};

  void recordGame() => totalGames++;
  void recordActive() => totalGamesActive++;
  void recordWin() => wins++;

  void recordFold(String phase, double winProb, double potOdds) {
    switch (phase) {
      case 'preflop':
        foldsPreflop++;
      case 'flop':
        foldsFlop++;
      case 'turn':
        foldsTurn++;
      case 'river':
        foldsRiver++;
    }
    totalWinProbAtFold += winProb;
    totalPotOddsAtFold += potOdds;
  }

  void recordAction(double winProb, double potOdds) {
    totalActions++;
    totalWinProbAtAction += winProb;
    totalPotOddsAtAction += potOdds;
  }

  void recordBeat(String opponent) {
    beats[opponent] = (beats[opponent] ?? 0) + 1;
  }

  Map<String, dynamic> toJson() {
    final totalFolds = foldsPreflop + foldsFlop + foldsTurn + foldsRiver;
    final avgFoldPhase = totalFolds == 0
        ? 0.0
        : (foldsPreflop * 0 + foldsFlop * 1 + foldsTurn * 2 + foldsRiver * 3) /
              totalFolds;

    return {
      'totalGames': totalGames,
      'totalGamesActive': totalGamesActive,
      'wins': wins,
      'winRate': totalGamesActive == 0 ? 0.0 : wins / totalGamesActive,
      'folds': {
        'preflop': foldsPreflop,
        'flop': foldsFlop,
        'turn': foldsTurn,
        'river': foldsRiver,
        'total': totalFolds,
      },
      'foldsNormalized': totalGamesActive == 0
          ? 0.0
          : totalFolds / totalGamesActive,
      'avgFoldPhase': avgFoldPhase,
      'avgWinProbAtFold': totalFolds == 0
          ? 0.0
          : totalWinProbAtFold / totalFolds,
      'avgPotOddsAtFold': totalFolds == 0
          ? 0.0
          : totalPotOddsAtFold / totalFolds,
      'avgWinProbAtAction': totalActions == 0
          ? 0.0
          : totalWinProbAtAction / totalActions,
      'avgPotOddsAtAction': totalActions == 0
          ? 0.0
          : totalPotOddsAtAction / totalActions,
      'beats': beats,
    };
  }
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
        outputSink: NullStringSink(),
      );

  @override
  Future<InputChar> readKey() async {
    return const InputChar.char('q');
  }
}

Future<void> runTournament(
  int maxRounds,
  Map<String, PlayerStats> allStats,
) async {
  final eventController = StreamController<GameEvent>();

  final tui = SilentTUI();
  final game = Game(tui, eventController: eventController);

  // Use only computer players
  game.players.removeWhere((p) => p is HumanPlayer);
  final dummy = DummyPlayer('Dummy');
  dummy.chips = const ChipsAmount(10000);
  game.players.add(dummy);

  for (final player in game.players) {
    allStats.putIfAbsent(player.name, () => PlayerStats());
  }

  String? currentWinner;
  final roundLosers = <String>[];

  final sub = eventController.stream.listen((event) {
    print(jsonEncode(event.toJson()));

    if (event.event == 'roundStart') {
      currentWinner = null;
      roundLosers.clear();

      final activePlayers = (event.data['players'] as List).cast<String>();
      for (final name in activePlayers) {
        allStats[name]?.recordActive();
      }
      for (final name in allStats.keys) {
        allStats[name]?.recordGame();
      }
    } else if (event.event == 'fold') {
      final name = event.data['player'] as String;
      final community = event.data['communityCards'] as String;
      final winProb = event.data['winProb'] as double;
      final pot = event.data['pot'] as int;
      final callAmount = event.data['callAmount'] as int;
      final potOdds = callAmount <= 0 ? 0.0 : callAmount / (pot + callAmount);

      final phase = _getPhase(community);
      allStats[name]?.recordFold(phase, winProb, potOdds);
    } else if (event.event == 'action') {
      final name = event.data['player'] as String;
      final winProb = event.data['winProb'] as double;
      final pot = event.data['pot'] as int;
      final callAmount = event.data['callAmount'] as int;
      final potOdds = callAmount <= 0 ? 0.0 : callAmount / (pot + callAmount);

      allStats[name]?.recordAction(winProb, potOdds);
    } else if (event.event == 'win') {
      final winner = event.data['player'] as String;
      allStats[winner]?.recordWin();
      currentWinner = winner;
      _recordBeats(currentWinner, roundLosers, allStats);
    } else if (event.event == 'lose') {
      final loser = event.data['player'] as String;
      roundLosers.add(loser);
      _recordBeats(currentWinner, roundLosers, allStats);
    }
  });

  await game.play(maxRounds: maxRounds);
  await sub.cancel();
  await eventController.close();
}

void _recordBeats(
  String? winner,
  List<String> losers,
  Map<String, PlayerStats> allStats,
) {
  if (winner == null || losers.isEmpty) return;
  for (final loser in losers) {
    allStats[winner]?.recordBeat(loser);
  }
  // Clear losers to avoid double counting if multiple win events happen (side pots?)
  // Actually, in case of multiple winners (split pot), this might be tricky.
  // But for now, let's just keep it simple.
  losers.clear();
}

String _getPhase(String community) {
  if (community.isEmpty) return 'preflop';
  final cards = community.split(' ');
  if (cards.length == 3) return 'flop';
  if (cards.length == 4) return 'turn';
  if (cards.length == 5) return 'river';
  return 'unknown';
}

class DummyPlayer extends ComputerPlayer {
  DummyPlayer(String name)
      : super(
          name,
          ComputerPlayingStyle.grandma,
          monteCarloIterations: 1,
          error: 0.0,
        );

  @override
  Future<BettingMove> chooseNextMove(
    ChipsAmount tableRaiseAmount,
    int numTimesTableRaised,
    ChipsAmount tableLastBet, {
    List<Card> community = const [],
    ChipsAmount potSize = const ChipsAmount(0),
    List<ChipsAmount> otherBets = const [],
  }) async {
    lastWinProb = 0.5;
    return bet < tableLastBet ? BettingMove.called : BettingMove.checked;
  }
}
