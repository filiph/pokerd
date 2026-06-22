import 'dart:convert';
import 'dart:io';

class TournamentData {
  final int id;
  int maxRound = 0;
  List<String> eliminationOrder = []; // Players eliminated in previous rounds (earliest to latest)
  String? lastWinner; // The player who won the very last 'win' event

  TournamentData(this.id);
}

void main(List<String> args) async {
  final filePath = args.isNotEmpty ? args[0] : 'temp_output_filip3.jsonl';
  final file = File(filePath);
  if (!await file.exists()) {
    print('File not found!');
    return;
  }

  final lines = await file.readAsLines();

  final tournaments = <TournamentData>[];
  TournamentData? currentTournament;
  
  Set<String> activePlayersInCurrentTournament = {};

  // All-ins stats
  final allInCount = <String, int>{};
  
  // Showdown stats
  final showdownWins = <String, Map<String, int>>{}; // player -> handRank -> count
  final foldWinsCount = <String, int>{}; // player -> count of wins because everyone else folded
  final eligibilityWinsCount = <String, int>{}; // player -> eligibility wins
  
  // Pot sizes
  int maxPot = 0;
  Map<String, dynamic>? maxPotEvent;
  
  // Best folded hands
  double maxFoldWinProb = 0.0;
  Map<String, dynamic>? maxFoldWinProbEvent;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    final event = jsonDecode(line) as Map<String, dynamic>;
    final eventName = event['event'] as String?;
    if (eventName == null) continue;

    if (eventName == 'roundStart') {
      final roundNumber = event['roundNumber'] as int;
      final players = List<String>.from(event['players'] as List);
      
      if (roundNumber == 1) {
        // Complete the previous tournament if any
        if (currentTournament != null) {
          tournaments.add(currentTournament);
        }
        currentTournament = TournamentData(tournaments.length + 1);
        activePlayersInCurrentTournament = {'Grandma', 'Kyle', 'Mr. Case', 'Michelle'};
      }
      
      currentTournament!.maxRound = roundNumber;
      
      // Check who was eliminated since the last round
      final eliminatedThisRound = activePlayersInCurrentTournament.difference(players.toSet());
      for (final p in eliminatedThisRound) {
        if (!currentTournament.eliminationOrder.contains(p)) {
          currentTournament.eliminationOrder.add(p);
        }
      }
      activePlayersInCurrentTournament = players.toSet();
    } else if (eventName == 'action') {
      final player = event['player'] as String;
      final move = event['move'] as String;
      if (move == 'allIn') {
        allInCount[player] = (allInCount[player] ?? 0) + 1;
      }
    } else if (eventName == 'fold') {
      final winProb = event['winProb'] as double;
      if (winProb > maxFoldWinProb) {
        maxFoldWinProb = winProb;
        maxFoldWinProbEvent = event;
      }
    } else if (eventName == 'win') {
      final player = event['player'] as String;
      final pot = event['pot'] as int;
      final handRank = event['handRank'] as String?;
      
      if (pot > maxPot) {
        maxPot = pot;
        maxPotEvent = event;
      }
      
      if (handRank == 'N/A' || event['hand'] == 'Eligibility') {
        eligibilityWinsCount[player] = (eligibilityWinsCount[player] ?? 0) + 1;
      } else if (handRank == 'Folded' || handRank == null) {
        foldWinsCount[player] = (foldWinsCount[player] ?? 0) + 1;
        currentTournament?.lastWinner = player;
      } else {
        showdownWins.putIfAbsent(player, () => {});
        showdownWins[player]![handRank] = (showdownWins[player]![handRank] ?? 0) + 1;
        currentTournament?.lastWinner = player;
      }
    }
  }

  // Add the final tournament
  if (currentTournament != null) {
    tournaments.add(currentTournament);
  }

  print('--- Comprehensive Log Analysis ---');
  print('Total tournaments played: ${tournaments.length}');
  
  // Calculate average duration of tournaments
  final avgRounds = tournaments.map((t) => t.maxRound).reduce((a, b) => a + b) / tournaments.length;
  print('Average rounds per tournament: ${avgRounds.toStringAsFixed(1)}');
  
  // Calculate tournament wins and placements for each player
  final firstPlaces = <String, int>{};
  final secondPlaces = <String, int>{};
  final thirdPlaces = <String, int>{};
  final fourthPlaces = <String, int>{};
  
  for (final t in tournaments) {
    final winner = t.lastWinner;
    if (winner == null) continue;

    firstPlaces[winner] = (firstPlaces[winner] ?? 0) + 1;

    // The other players' placements are determined by the elimination order
    // plus anyone in the last round who was NOT the winner (they got 2nd place).
    final order = List<String>.from(t.eliminationOrder);
    
    // Add any last round player who was NOT the winner to the order at the end (2nd place)
    final lastRoundOtherPlayers = {'Grandma', 'Kyle', 'Mr. Case', 'Michelle'}
        .difference(order.toSet())
        .difference({winner});
    
    for (final p in lastRoundOtherPlayers) {
      order.add(p);
    }
    
    // Now order list contains: [4th place, 3rd place, 2nd place]
    if (order.isNotEmpty) {
      final second = order.last;
      secondPlaces[second] = (secondPlaces[second] ?? 0) + 1;
    }
    if (order.length >= 2) {
      final third = order[order.length - 2];
      thirdPlaces[third] = (thirdPlaces[third] ?? 0) + 1;
    }
    if (order.length >= 3) {
      final fourth = order[order.length - 3];
      fourthPlaces[fourth] = (fourthPlaces[fourth] ?? 0) + 1;
    }
  }

  print('\n--- Tournament Standings ---');
  print('Player      | 1st Place (Sole Winner) | 2nd Place | 3rd Place | 4th Place (First Out)');
  print('----------------------------------------------------------------------------------');
  for (final player in ['Grandma', 'Kyle', 'Mr. Case', 'Michelle']) {
    final first = firstPlaces[player] ?? 0;
    final second = secondPlaces[player] ?? 0;
    final third = thirdPlaces[player] ?? 0;
    final fourth = fourthPlaces[player] ?? 0;
    print('${player.padRight(11)} | ${first.toString().padRight(23)} | ${second.toString().padRight(9)} | ${third.toString().padRight(9)} | $fourth');
  }

  print('\n--- Wins Breakdowns ---');
  print('Player      | Showdown Wins | fold-out Wins | Eligibility / returned chips');
  print('--------------------------------------------------------------------------');
  for (final player in ['Grandma', 'Kyle', 'Mr. Case', 'Michelle']) {
    final showWins = (showdownWins[player] ?? {}).values.fold<int>(0, (a, b) => a + b);
    final fWins = foldWinsCount[player] ?? 0;
    final eWins = eligibilityWinsCount[player] ?? 0;
    print('${player.padRight(11)} | ${showWins.toString().padRight(13)} | ${fWins.toString().padRight(13)} | $eWins');
  }

  print('\n--- Showdown Wins by Hand Rank (Excluding Eligibility) ---');
  for (final player in ['Grandma', 'Kyle', 'Mr. Case', 'Michelle']) {
    print('- $player:');
    final ranks = showdownWins[player] ?? {};
    final sortedRanks = ranks.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sortedRanks) {
      print('  * ${entry.key}: ${entry.value}');
    }
  }

  print('\n--- Aggression Indicators ---');
  print('Player      | All-In Moves Count');
  print('---------------------------------');
  for (final player in ['Grandma', 'Kyle', 'Mr. Case', 'Michelle']) {
    print('${player.padRight(11)} | ${allInCount[player] ?? 0}');
  }

  print('\n--- Interesting Hands ---');
  print('Max Pot size: $maxPot chips (Won by ${maxPotEvent?['player']} with hand rank ${maxPotEvent?['handRank']} and community ${maxPotEvent?['communityCards']})');
  print('Max win probability folded: $maxFoldWinProb (by ${maxFoldWinProbEvent?['player']} with cards ${maxFoldWinProbEvent?['playerCards']} and community ${maxFoldWinProbEvent?['communityCards']})');
}
