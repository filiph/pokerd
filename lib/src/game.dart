import 'dart:math';

import 'package:pokerd/src/ansi.dart';

import 'betting_move.dart';
import 'computer_player.dart';
import 'deck.dart';
import 'hand_rank.dart';
import 'human_player.dart';
import 'phase.dart';
import 'player.dart';
import 'table.dart';
import 'terminal_ui.dart';

class Game {
  Phase phase = Phase.preflop;
  final Deck deck = Deck();
  final List<Player> players = [];
  Player? dealer;
  final Table table = Table();
  final TerminalUI tui;
  int speed = 300;
  bool useColor = false;

  Game(this.tui) {
    setup();
  }

  void setup() {
    final human = HumanPlayer('Player', tui);
    players.add(human);

    final names = [
      'Homer',
      'Bart',
      'Lisa',
      'Marge',
      'Milhouse',
      'Moe',
      'Maggie',
      'Nelson',
      'Ralph',
    ];
    final computerNames = names.where((name) => name != 'Player').toList()
      ..shuffle();

    for (var i = 0; i < 4; i++) {
      final style = ComputerPlayingStyle
          .values[Random().nextInt(ComputerPlayingStyle.values.length)];
      players.add(ComputerPlayer(computerNames[i], style));
    }

    for (final player in players) {
      player.chips = 10000;
    }

    table.bigBlind = 200;
  }

  List<Player> getActivePlayers() => players.where((p) => p.isInGame).toList();

  Future<void> play() async {
    while (true) {
      await resetForNextRound();
      for (final phaseVal in Phase.values) {
        phase = phaseVal;
        await dealCards();
        await runRoundOfBetting();
        if (checkHandOver()) {
          break;
        }
      }
      await determineWinners();
      table.handsPlayed += 1;
      if (await checkGameOver()) {
        break;
      }
    }
  }

  Future<void> resetForNextRound() async {
    resetPlayers();
    await resetTable();
    await resetDeck();
  }

  /// Returns `true` if human player is active in the current round
  /// (is among [getActivePlayers] and is not [Player.isFolded]).
  bool get hasActiveHumanPlayerInRound =>
      getActivePlayers().any((p) => p is HumanPlayer && !p.isFolded);

  void resetPlayers() {
    for (final player in players) {
      player.reset();
    }
    assignPositions();
  }

  Future<void> resetTable() async {
    final active = getActivePlayers();
    table.reset(active);
    if (table.checkIncreaseBigBlind()) {
      await showBlindIncrease();
    }
  }

  Future<void> resetDeck() async {
    deck.refill();
    deck.shuffle();
    await showShuffling();
  }

  void assignPositions() {
    for (final player in getActivePlayers()) {
      player.isSB = false;
      player.isBB = false;
    }
    if (table.handsPlayed == 0) {
      determinePositionsRandomly();
    } else {
      shiftPositionsLeft();
    }
  }

  void determinePositionsRandomly() {
    final active = getActivePlayers();
    final dealerIndex = Random().nextInt(active.length);
    active[dealerIndex].isDealer = true;
    dealer = active[dealerIndex];
    if (active.length == 2) {
      active[dealerIndex].isSB = true;
      active[(dealerIndex + 1) % active.length].isBB = true;
    } else {
      active[(dealerIndex + 2) % active.length].isBB = true;
      active[(dealerIndex + 1) % active.length].isSB = true;
    }
  }

  void shiftPositionsLeft() {
    final active = getActivePlayers();
    var oldDealerIndex = players.indexOf(dealer!);
    while (true) {
      oldDealerIndex += 1;
      final playerToLeft = players[oldDealerIndex % players.length];
      if (active.contains(playerToLeft)) {
        dealer = playerToLeft;
        playerToLeft.isDealer = true;
        final newDealerIndex = active.indexOf(dealer!);
        if (active.length == 2) {
          active[newDealerIndex].isSB = true;
          active[(newDealerIndex + 1) % active.length].isBB = true;
        } else {
          active[(newDealerIndex + 2) % active.length].isBB = true;
          active[(newDealerIndex + 1) % active.length].isSB = true;
        }
        break;
      }
    }
  }

  Future<void> dealCards() async {
    await showPhaseChangeAlert(phase, dealer!.name);
    switch (phase) {
      case Phase.preflop:
        await dealHole();
      case Phase.flop:
        dealCommunity(3);
      case Phase.turn:
        dealCommunity(1);
      case Phase.river:
        dealCommunity(1);
    }
  }

  Future<void> dealHole() async {
    await showDealingHole(dealer!.name);
    for (var i = 0; i < 2; i++) {
      for (final player in getActivePlayers()) {
        final cards = deck.deal(1);
        player.hand.addAll(cards);
      }
    }

    if (hasActiveHumanPlayerInRound) {
      final humanPlayer =
          players.firstWhere((p) => p is HumanPlayer) as HumanPlayer;
      await tui.write(
        '${humanPlayer.name} got:  '
        '${TerminalUI.formatHand(humanPlayer.hand, showFace: true, useColor: useColor)}\n\n',
      );
    }
  }

  void dealCommunity(int n) {
    deck.burn();
    final cards = deck.deal(n);
    table.community.addAll(cards);
  }

  Future<void> runRoundOfBetting() async {
    table.numTimesRaised = 0;
    final active = getActivePlayers();
    if (phase == Phase.preflop) {
      await runSmallBlindBet();
      await runBigBlindBet();
    }
    final firstAct = getIndexFirstAct();
    await betUntilAllLockedIn(firstAct, active);
    for (final player in active) {
      if (!player.isFolded && !player.isAllIn) {
        player.isLocked = false;
      }
    }
    table.calculateSidePots(active);
  }

  Future<void> runSmallBlindBet() async {
    final player = players.firstWhere((p) => p.isSB);
    await showBetBlind(player.name, 'small');
    final wentAllIn = table.takeSmallBlind(player);
    if (wentAllIn) {
      await showPlayerMove(player, BettingMove.allIn, player.bet);
    }
  }

  Future<void> runBigBlindBet() async {
    final player = players.firstWhere((p) => p.isBB);
    await showBetBlind(player.name, 'big');
    final wentAllIn = table.takeBigBlind(player);
    if (wentAllIn) {
      await showPlayerMove(player, BettingMove.allIn, player.bet);
    }
  }

  int getIndexFirstAct() {
    final active = getActivePlayers();
    if (active.length == 2) {
      return active[0].isDealer ? 0 : 1;
    }
    if (phase == Phase.preflop) {
      final bbIndex = active.indexWhere((p) => p.isBB);
      return (bbIndex + 1) % active.length;
    } else {
      final dealerIndex = active.indexWhere((p) => p.isDealer);
      return (dealerIndex + 1) % active.length;
    }
  }

  Future<void> betUntilAllLockedIn(
    int firstAct,
    List<Player> activePlayers,
  ) async {
    var bettingIndex = firstAct;
    while (true) {
      if (activePlayers.every((p) => p.isLocked || p.isAllIn)) {
        break;
      }
      if (activePlayers.where((p) => !p.isFolded).length == 1) {
        break;
      }
      final bettingPlayer = activePlayers[bettingIndex % activePlayers.length];
      if (bettingPlayer.isFolded || bettingPlayer.isAllIn) {
        bettingIndex += 1;
        continue;
      }
      table.updateRaiseAmount(phase);
      if (bettingPlayer is ComputerPlayer) {
        // Nothing to show. (Previously, we showed "$player is thinking...".)
      } else if (bettingPlayer is HumanPlayer) {
        await showTable();
      }
      final move = await bettingPlayer.chooseNextMove(
        table.raiseAmount,
        table.numTimesRaised,
        table.lastBet,
      );
      if (bettingPlayer is HumanPlayer &&
          (move == BettingMove.bet || move == BettingMove.raised)) {
        table.raiseAmount = bettingPlayer.customBet;
      }
      table.takeBet(bettingPlayer, move);
      await showPlayerMove(bettingPlayer, move, bettingPlayer.bet);
      if (move == BettingMove.raised || move == BettingMove.bet) {
        for (final activePlayer in activePlayers) {
          if (!activePlayer.isFolded) {
            activePlayer.isLocked = false;
          }
        }
        for (final person in activePlayers) {
          if (person.isAllIn) {
            person.isLocked = true;
          }
        }
      }
      bettingPlayer.isLocked = true;
      bettingIndex += 1;
    }
  }

  bool checkHandOver() {
    var playersAbleToBet = 0;
    for (final player in getActivePlayers()) {
      if (!player.isAllIn && !player.isFolded) {
        playersAbleToBet += 1;
      }
    }
    return playersAbleToBet < 2;
  }

  Future<void> determineWinners() async {
    if (table.pots.last.amount == 0) {
      table.pots.removeLast();
    }
    final unfoldedPlayers = getActivePlayers()
        .where((p) => !p.isFolded)
        .toList();
    if (unfoldedPlayers.length == 1) {
      var winnings = 0;
      for (final pot in table.pots) {
        winnings += pot.amount;
      }
      final winner = unfoldedPlayers[0];
      winner.chips += winnings;
      await showDefaultWinnerFold(winner.name);
    } else {
      final playersEligibleLastPot = <Player>[];
      for (final player in table.pots.last.players) {
        if (!player.isFolded) {
          playersEligibleLastPot.add(player);
        }
      }
      if (playersEligibleLastPot.length == 1) {
        final handWinner = playersEligibleLastPot[0];
        await showDefaultWinnerEligibility(
          handWinner.name,
          table.pots.length - 1,
        );
        handWinner.chips += table.pots.last.amount;
        table.pots.removeLast();
      }
      while (table.community.length < 5) {
        table.community.addAll(deck.deal(1));
      }
      await showdown();
    }
  }

  Future<void> showdown() async {
    for (var i = table.pots.length - 1; i >= 0; i--) {
      final showdownPlayers = <Player>[];
      for (final player in table.pots[i].players) {
        if (!player.isFolded) {
          showdownPlayers.add(player);
        }
      }
      final handWinners = HandRank.determineShowdownWinner(
        showdownPlayers,
        table.community,
      );
      for (final winner in handWinners) {
        winner.chips += table.pots[i].amount ~/ handWinners.length;
      }
      await showShowdownResults(handWinners, showdownPlayers, i);
    }
  }

  Future<bool> checkGameOver() async {
    for (final player in getActivePlayers()) {
      if (player.chips == 0) {
        player.isInGame = false;
      }
    }
    final active = getActivePlayers();
    if (active.length == 1) {
      await showGameWinners([active[0].name]);
      return true;
    } else {
      const tuiKey = 'press_to_continue';
      await tui.writeInPlace(tuiKey, [
        '> Continue on to next hand?',
        ansi('> Press [Q] to stop, [any] other key to continue.'),
      ]);
      final key = await tui.readKey();
      final char = key.char?.toLowerCase();
      if (char == 'q') {
        await tui.writeInPlace(tuiKey, ['Ending game.', '']);
        final maxChips = active.map((p) => p.chips).reduce(max);
        final winnersNames = active
            .where((p) => p.chips == maxChips)
            .map((p) => p.name)
            .toList();
        await showGameWinners(winnersNames);
        return true;
      } else {
        await tui.writeInPlace(tuiKey, ['Continuing.', '']);
        return false;
      }
    }
  }

  Future<void> showShuffling() async {
    await tui.write('Deck is being shuffled...\n\n');
  }

  Future<void> showDealingHole(String dealerName) async {
    await tui.write('$dealerName is dealing cards to players...\n\n');
  }

  Future<void> showBlindIncrease() async {
    await tui.write('The big blind has increased to ${table.bigBlind}!\n\n');
  }

  Future<void> showPlayerMove(Player player, BettingMove move, int? bet) async {
    final bool importantMove;
    switch (move) {
      case BettingMove.folded:
        await tui.write('${player.name} folded! ×\n\n');
        importantMove = true;
      case BettingMove.checked:
        await tui.write('${player.name} checked. √\n\n');
        importantMove = false;
      case BettingMove.allIn:
        await tui.write('${player.name} went all-in!\n\n');
        importantMove = true;
      case BettingMove.called:
        await tui.write('${player.name} called ${player.bet}¤. ←→\n\n');
        importantMove = false;
      case BettingMove.bet:
        await tui.write('${player.name} bet ${player.bet}¤. ↑\n\n');
        importantMove = true;
      case BettingMove.raised:
        await tui.write('${player.name} raised to ${player.bet}¤. ↑\n\n');
        importantMove = true;
    }

    if (importantMove &&
        player is! HumanPlayer &&
        hasActiveHumanPlayerInRound) {
      await tui.waitForAnyKey();
    }
  }

  Future<void> showBetBlind(String playerName, String blindSize) async {
    await tui.write('$playerName bet the $blindSize blind\n\n');
  }

  Future<void> showDefaultWinnerFold(String playerName) async {
    await tui.write('All other players folded...\n');
    await tui.write('$playerName won the pot!\n\n');
    await tui.waitForAnyKey();
  }

  Future<void> showDefaultWinnerEligibility(
    String playerName,
    int sidePotNum,
  ) async {
    await tui.write(
      '\n$playerName is the only player eligible for SIDE POT #$sidePotNum.\n',
    );
    await tui.write('Gave those chips to $playerName.\n\n');
    await tui.waitForAnyKey();
  }

  Future<void> showPhaseChangeAlert(Phase phase, String dealer) async {
    if (phase == Phase.preflop) {
      await tui.write('Preflop Round: $dealer is the dealer!\n\n');
    } else {
      final nameCapitalized =
          phase.name[0].toUpperCase() + phase.name.substring(1);
      await tui.write('Round Change: the $nameCapitalized!\n\n');
    }
  }

  Future<void> showTable({bool isShowdown = false}) async {
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => (b.isInGame ? 1 : 0).compareTo(a.isInGame ? 1 : 0));

    await tui.write(
      '${' ' * 12}    ${'HAND'.padRight(12)}   ${'BET'.padLeft(7)}'
      '   ${'CHIPS'.padLeft(7)}   STATUS\n',
    );
    await tui.write('=' * 79 + '\n', speedOverride: 1000);
    for (final player in sortedPlayers) {
      final strBuf = StringBuffer();
      strBuf.write(player.name.padLeft(12));
      strBuf.write(':   ');

      if (!player.isInGame) {
        strBuf.write('[OUT OF GAME]');
      } else {
        strBuf.write(
          TerminalUI.formatHand(
            player.hand,
            showFace: player is HumanPlayer || isShowdown,
            empty: player.isFolded || player.hand.isEmpty,
            useColor: useColor,
          ),
        );

        strBuf.write('   ');

        strBuf.write('${player.bet.toString().padLeft(6)}¤');

        strBuf.write('   ');

        if (player.isAllIn) {
          strBuf.write(' all-in');
        } else {
          strBuf.write('${player.chips.toString().padLeft(6)}¤');
        }

        strBuf.write('   ');

        if (isShowdown) {
          if (player.bestHandRank != null) {
            strBuf.write(
              '${player.bestHandRank!.description}${player.rankSubtype}',
            );
          }
        } else {
          if (player.isDealer) {
            strBuf.write('(Dealer)');
          }
          if (player.isSB) {
            strBuf.write('(SB)');
          }
          if (player.isBB) {
            strBuf.write('(BB)');
          }
        }
      }
      strBuf.writeln();

      await tui.write(strBuf.toString(), speedOverride: 1000);
    }
    await tui.write('\n');

    final communityCards = TerminalUI.formatHand(
      table.community,
      showFace: true,
      useColor: useColor,
    );
    await tui.write(
      '${'Community'.padLeft(12)}:   $communityCards\n\n',
      speedOverride: 1000,
    );

    await tui.write(
      '${'Small Blind'.padLeft(12)}: '
      '${(table.bigBlind ~/ 2).toString().padLeft(6)}¤\n',
      speedOverride: 1000,
    );
    await tui.write(
      '${'Big Blind'.padLeft(12)}: '
      '${table.bigBlind.toString().padLeft(6)}¤\n',
      speedOverride: 1000,
    );

    final mainPot = table.pots[0];
    await tui.write(
      '${'POT'.padLeft(12)}: '
      '${mainPot.amount.toString().padLeft(6)}¤\n',
      speedOverride: 1000,
    );
    for (var i = 1; i < table.pots.length; i++) {
      final sidePot = table.pots[i];
      await tui.write(
        '${'SIDE POT #$i'.padLeft(12)}: '
        '${sidePot.amount.toString().padLeft(6)}¤\n',
        speedOverride: 1000,
      );
    }
    await tui.write('=' * 79 + '\n', speedOverride: 1000);
  }

  Future<void> showShowdownResults(
    List<Player> handWinners,
    List<Player> showdownPlayers,
    int potNum,
  ) async {
    await showTable(isShowdown: true);
    await showPotWinners(handWinners, showdownPlayers, potNum);
    await tui.waitForAnyKey();
  }

  Future<void> showPotWinners(
    List<Player> handWinners,
    List<Player> showdownPlayers,
    int potNum,
  ) async {
    var potType = 'the pot';
    if (potNum > 0) {
      potType = 'SIDE POT #$potNum';
      final playersStr = showdownPlayers.map((p) => p.name).join('   ');
      await tui.write(
        '           Players eligible for SIDE POT #$potNum:      $playersStr\n\n',
      );
    }
    if (handWinners.length == 1) {
      final winner = handWinners[0];
      final handStr = TerminalUI.formatHand(
        winner.bestHandCards,
        showFace: true,
        useColor: useColor,
      );
      final rankStr = winner.bestHandRank?.description ?? '';
      await tui.write(
        '           $handStr      ${winner.name} won $potType with a $rankStr${winner.rankSubtype}!\n',
      );
      if (winner.kickerCard != null) {
        final kickerStr =
            'Kicker card was the '
            '${TerminalUI.formatCard(winner.kickerCard!, showFace: true, useColor: useColor)}';
        await tui.write('${kickerStr.padLeft(75)}\n\n');
      } else {
        await tui.write('\n');
      }
    } else {
      for (var i = 0; i < handWinners.length; i++) {
        final winner = handWinners[i];
        final handStr = TerminalUI.formatHand(
          winner.bestHandCards,
          showFace: true,
          useColor: useColor,
        );
        await tui.write('           $handStr      ${winner.name}\n');
        if (i == handWinners.length - 1) {
          final rankStr = winner.bestHandRank?.description ?? '';
          await tui.write(
            '\n\n           Split $potType with a $rankStr${winner.rankSubtype}!\n',
          );
          if (winner.kickerCard != null) {
            final kickerStr =
                'Kicker card was the  ${winner.kickerCard!.rank.symbol}';
            await tui.write('${kickerStr.padLeft(33)}\n\n');
          }
        }
      }
      await tui.write('\n');
    }
  }

  Future<void> showGameWinners(List<String> winnersNames) async {
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => b.chips.compareTo(a.chips));

    for (final player in sortedPlayers) {
      final nameStr = player.name.padRight(12);
      final chipsStr = 'Chips:${player.chips.toString().padLeft(6)}';
      await tui.write('${nameStr.padLeft(44)}${chipsStr.padLeft(18)}\n');
    }
    await tui.write('\n\n\n\n\n');

    String winnersStr;
    if (winnersNames.length == 1) {
      winnersStr = winnersNames[0];
    } else if (winnersNames.length == 2) {
      winnersStr = '${winnersNames[0]} and ${winnersNames[1]}';
    } else {
      winnersStr =
          '${winnersNames.sublist(0, winnersNames.length - 1).join(', ')}, and ${winnersNames.last}';
    }
    await tui.write('   $winnersStr won the game!\n\n');
    await tui.write('========================================\n');
    await tui.write('               GAME OVER                \n');
    await tui.write('========================================\n\n');
  }
}
