import 'dart:async';
import 'dart:math';

import 'package:meta/meta.dart';
import 'package:pokerd/src/ansi.dart';
import 'package:tint/tint.dart';

import 'betting_move.dart';
import 'card.dart';
import 'chips_amount.dart';
import 'computer_player.dart';
import 'deck.dart';
import 'hand_rank.dart';
import 'human_player.dart';
import 'phase.dart';
import 'player.dart';
import 'table.dart';
import 'terminal_ui.dart';
import 'tutorial.dart';
import 'game_event.dart';

class Game {
  Phase phase = Phase.preflop;
  final Deck deck = Deck();
  final List<Player> players = [];
  Player? dealer;
  final Table table = Table();
  final TerminalUI tui;
  final int speed;
  final bool useColor;
  final StreamController<GameEvent>? eventController;

  Game(
    this.tui, {
    this.speed = 300,
    this.useColor = false,
    this.eventController,
  }) {
    setup();
  }

  void setup() {
    final human = HumanPlayer('Player');
    players.add(human);

    players.addAll(ComputerPlayer.createDefaultPlayers());

    for (final player in players) {
      player.chips = const ChipsAmount(10000);
    }

    table.bigBlind = const ChipsAmount(200);
  }

  void _emit(GameEvent event) {
    eventController?.add(event);
  }

  List<Player> getActivePlayers() => players.where((p) => p.isInGame).toList();

  Future<void> play({int? maxRounds}) async {
    await tui.write(
      '· Players joining: '
              '${getActivePlayers().map((p) => p.name).join(', ')}.\n'
          .dim(),
    );

    while (true) {
      if (maxRounds != null && table.handsPlayed >= maxRounds) {
        break;
      }
      await resetForNextRound();
      _emit(
        GameEvent.roundStart(
          roundNumber: table.handsPlayed + 1,
          players: getActivePlayers().map((p) => p.name).toList(),
        ),
      );
      try {
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
      } on _QuitException {
        // Player chose to quit during their turn.
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

  /// Deals cards for the current [phase].
  Future<void> dealCards() async {
    await showPhaseChangeAlert(phase, dealer!.name);

    Future<void> showPlayerVisibleCards(
      String preambule,
      List<Card> cards,
    ) async {
      final slow = hasActiveHumanPlayerInRound;

      await tui.write('· $preambule:  ');
      if (slow) await Future<void>.delayed(Duration(milliseconds: 300));
      await tui.write(
        TerminalUI.formatHand(cards, showFace: true, useColor: useColor),
        speedOverride: slow ? speed ~/ 10 : null,
        charsPerWrite: 1,
      );
      if (slow) await Future<void>.delayed(Duration(milliseconds: 300));
      await tui.write('\n');
    }

    switch (phase) {
      case Phase.preflop:
        await dealHole();

        if (hasActiveHumanPlayerInRound) {
          final humanPlayer =
              players.firstWhere((p) => p is HumanPlayer) as HumanPlayer;
          await showPlayerVisibleCards(
            '${humanPlayer.name} got',
            humanPlayer.hand,
          );
        }

      case Phase.flop:
        final cards = dealCommunity(3);
        await showPlayerVisibleCards('Flop cards', cards);

      case Phase.turn:
        final cards = dealCommunity(1);
        await showPlayerVisibleCards('Turn cards', cards);

      case Phase.river:
        final cards = dealCommunity(1);
        await showPlayerVisibleCards('River cards', cards);
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
  }

  /// Deals [n] community cards, burning one card first.
  /// Adds the cards to [Table.community] and returns them.
  List<Card> dealCommunity(int n) {
    deck.burn();
    final cards = deck.deal(n);
    table.community.addAll(cards);
    return cards;
  }

  Future<void> runRoundOfBetting() async {
    table.numTimesRaised = 0;
    table.lastBet = const ChipsAmount(0);
    table.minRaiseIncrement = table.bigBlind;
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

      final potSize =
          table.pots.fold<ChipsAmount>(
            const ChipsAmount(0),
            (sum, pot) => sum + pot.amount,
          ) +
          activePlayers.fold<ChipsAmount>(
            const ChipsAmount(0),
            (sum, p) => sum + p.bet,
          );

      final BettingMove move;
      if (bettingPlayer is HumanPlayer) {
        await showTable();
        move = await getHumanMove(bettingPlayer);
        tui.write('\n');
      } else if (bettingPlayer is ComputerPlayer) {
        move = await bettingPlayer.chooseNextMove(
          table.raiseAmount,
          table.numTimesRaised,
          table.lastBet,
          community: table.community,
          potSize: potSize,
          otherBets: activePlayers
              .where((p) => p != bettingPlayer && !p.isFolded)
              .map((p) => p.bet)
              .toList(),
        );
      } else {
        throw StateError('Unknown player type: ${bettingPlayer.runtimeType}');
      }

      if (bettingPlayer is HumanPlayer &&
          (move == BettingMove.bet || move == BettingMove.raised)) {
        table.raiseAmount = bettingPlayer.customBet;
      }
      final oldLastBet = table.lastBet;
      final callAmount = oldLastBet - bettingPlayer.bet;
      table.takeBet(bettingPlayer, move);

      if (move == BettingMove.folded) {
        _emit(
          GameEvent.fold(
            player: bettingPlayer.name,
            playerCards: List.from(bettingPlayer.hand),
            communityCards: List.from(table.community),
            winProb:
                (bettingPlayer is ComputerPlayer)
                    ? (bettingPlayer as ComputerPlayer).lastWinProb
                    : 0.0,
            pot: potSize,
            lastBet: oldLastBet,
            callAmount: callAmount,
            bet: bettingPlayer.bet,
          ),
        );
      } else {
        _emit(
          GameEvent.action(
            player: bettingPlayer.name,
            move: move,
            playerCards: List.from(bettingPlayer.hand),
            communityCards: List.from(table.community),
            winProb:
                (bettingPlayer is ComputerPlayer)
                    ? (bettingPlayer as ComputerPlayer).lastWinProb
                    : 0.0,
            pot: potSize,
            lastBet: oldLastBet,
            callAmount: callAmount,
            bet: bettingPlayer.bet,
          ),
        );
      }

      await showPlayerMove(bettingPlayer, move, bettingPlayer.bet);
      if (table.lastBet > oldLastBet) {
        for (final activePlayer in activePlayers) {
          if (!activePlayer.isFolded) {
            if (table.lastRaiseWasFull) {
              activePlayer.isLocked = false;
              activePlayer.onlyCallOrFold = false;
            } else {
              if (activePlayer.bet < table.lastBet) {
                if (activePlayer.isLocked) {
                  activePlayer.onlyCallOrFold = true;
                }
                activePlayer.isLocked = false;
              }
            }
          }
        }
        for (final person in activePlayers) {
          if (person.isAllIn) {
            person.isLocked = true;
          }
        }
      }
      bettingPlayer.isLocked = true;
      bettingPlayer.onlyCallOrFold = false; // Reset after they acted
      bettingIndex += 1;
    }
  }

  @visibleForTesting
  Future<BettingMove> getHumanMove(HumanPlayer player) async {
    player.customBet = table.raiseAmount;

    while (true) {
      List<String> validMoves;
      String prompt;
      bool canAdjust = false;

      // If player doesn't have enough chips to raise or if player has just enough chips to raise
      if (player.chips <= (player.bet - table.raiseAmount).abs()) {
        // If not enough chips to call
        if (player.chips <= (player.bet - table.lastBet).abs()) {
          validMoves = ['f', 'a'];
          prompt = '${'●'.green()}   [A]ll-in   [F]old   [O]ptions';
        } else {
          validMoves = ['c', 'a', 'f'];
          prompt =
              '${'●'.green()}   [C]all ${table.lastBet}  [A]ll-in   [F]old   [O]ptions';
        }
      } else if (table.numTimesRaised < 4 && !player.onlyCallOrFold) {
        canAdjust = true;
        if (player.bet == table.lastBet) {
          validMoves = ['c', 'b', 'a', 'f'];
          prompt =
              '${'●'.green()}   [C]heck   [B]et [←]${player.customBet}[→]   [A]ll-in   [F]old   [O]ptions';
        } else {
          validMoves = ['c', 'r', 'a', 'f'];
          prompt =
              '${'●'.green()}   [C]all ${table.lastBet}   [R]aise to [←]${player.customBet}[→]   [A]ll-in   [F]old   [O]ptions';
        }
      } else {
        validMoves = ['c', 'a', 'f'];
        prompt =
            '${'●'.green()}   [C]all ${table.lastBet}   [A]ll-in   [F]old   [O]ptions';
      }

      final underlinedPrompt = ansi(prompt);
      await tui.writeInPlace('human_prompt', ['', underlinedPrompt]);

      final key = await tui.readKey();
      if (key.isLeft && canAdjust) {
        if (player.customBet > table.raiseAmount) {
          if (player.customBet - const ChipsAmount(100) >= table.raiseAmount) {
            player.customBet -= const ChipsAmount(100);
          } else {
            player.customBet = table.raiseAmount;
          }
        }
      } else if (key.isRight && canAdjust) {
        final maxBet = player.chips + player.bet;
        if (player.customBet < maxBet) {
          if (player.customBet + const ChipsAmount(100) <= maxBet) {
            player.customBet += const ChipsAmount(100);
          } else {
            player.customBet = maxBet;
          }
        }
      } else {
        final char = key.char?.toLowerCase();

        if (char == 'o') {
          await tui.writeInPlace('human_prompt', [
            '',
            ansi(
              '${'●'.dim()} ${'●'.green()}   Options:   '
              '[Q]uit   [H]and Rankings   [R]ules   '
              '[Any] other key to go back',
            ),
          ]);
          final key = await tui.readKey();
          switch (key.char?.toLowerCase()) {
            case 'q':
              await tui.writeInPlace('human_prompt', ['', 'Ending game.', '']);
              throw _QuitException();
            case 'h':
              await showRankingsHelp(tui, useColor: useColor);
            case 'r':
              await showRules(tui);
            default:
              // Pass.
              break;
          }
          continue;
        }

        if (char != null && validMoves.contains(char)) {
          if (char == 'b') {
            return BettingMove.bet;
          } else if (char == 'r') {
            return BettingMove.raised;
          } else if (char == 'f') {
            return BettingMove.folded;
          } else if (char == 'a') {
            return BettingMove.allIn;
          } else if (player.bet == table.lastBet) {
            return BettingMove.checked;
          } else {
            return BettingMove.called;
          }
        }
      }
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
    if (table.pots.last.amount == const ChipsAmount(0)) {
      table.pots.removeLast();
    }
    final unfoldedPlayers = getActivePlayers()
        .where((p) => !p.isFolded)
        .toList();
    if (unfoldedPlayers.length == 1) {
      var winnings = const ChipsAmount(0);
      for (final pot in table.pots) {
        winnings += pot.amount;
      }
      final winner = unfoldedPlayers[0];
      winner.chips += winnings;
      await showDefaultWinnerFold(winner.name, winnings);
      _emit(
        GameEvent.win(
          player: winner.name,
          playerCards: List.from(winner.hand),
          communityCards: List.from(table.community),
          hand: 'Folded',
          handRank: 'Folded',
          pot: winnings,
        ),
      );
    } else {
      final playersEligibleLastPot = <Player>[];
      for (final player in table.pots.last.players) {
        if (!player.isFolded) {
          playersEligibleLastPot.add(player);
        }
      }
      if (playersEligibleLastPot.length == 1) {
        final handWinner = playersEligibleLastPot[0];
        final amount = table.pots.last.amount;
        await showDefaultWinnerEligibility(
          handWinner.name,
          table.pots.length - 1,
          amount,
        );
        handWinner.chips += amount;
        _emit(
          GameEvent.win(
            player: handWinner.name,
            playerCards: List.from(handWinner.hand),
            communityCards: List.from(table.community),
            hand: 'Eligibility',
            handRank: 'N/A',
            pot: amount,
          ),
        );
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
      final share = table.pots[i].amount ~/ handWinners.length;
      var remainder = table.pots[i].amount % handWinners.length;

      for (final winner in handWinners) {
        winner.chips += share;
        _emit(
          GameEvent.win(
            player: winner.name,
            playerCards: List.from(winner.hand),
            communityCards: List.from(table.community),
            hand: winner.bestHandCards.map((c) => c.pokerNotation).join(' '),
            handRank: winner.bestHandRank.toString(),
            pot: share,
          ),
        );
      }

      for (final player in showdownPlayers) {
        if (!handWinners.contains(player)) {
          _emit(
            GameEvent.lose(
              player: player.name,
              playerCards: List.from(player.hand),
              communityCards: List.from(table.community),
              hand: player.bestHandCards.map((c) => c.pokerNotation).join(' '),
              handRank: player.bestHandRank.toString(),
            ),
          );
        }
      }

      if (remainder.value > 0) {
        final active = getActivePlayers();
        final dealerIndex = active.indexOf(dealer!);
        for (var j = 1; j <= active.length; j++) {
          final player = active[(dealerIndex + j) % active.length];
          if (handWinners.contains(player)) {
            player.chips += const ChipsAmount(1);
            remainder -= const ChipsAmount(1);
            if (remainder.value == 0) break;
          }
        }
      }
      await showShowdownResults(handWinners, showdownPlayers, i, share);
    }
  }

  Future<bool> checkGameOver() async {
    for (final player in getActivePlayers()) {
      if (player.chips == const ChipsAmount(0)) {
        player.isInGame = false;
      }
    }
    final active = getActivePlayers();
    if (active.length == 1) {
      await showGameWinners([active[0].name]);
      return true;
    } else {
      if (!players.any((p) => p is HumanPlayer)) {
        return false;
      }
      const tuiKey = 'press_to_continue';
      await tui.writeInPlace(tuiKey, [
        '${'●'.green()}   Continue on to next hand? ',
        ansi('    Press [Q] to stop, [any] other key to continue.'),
      ]);
      final key = await tui.readKey();
      final char = key.char?.toLowerCase();
      if (char == 'q') {
        await tui.writeInPlace(tuiKey, ['· Ending game.', '']);
        final maxChips = active.map((p) => p.chips.value).reduce(max);
        final winnersNames = active
            .where((p) => p.chips.value == maxChips)
            .map((p) => p.name)
            .toList();
        await showGameWinners(winnersNames);
        return true;
      } else {
        await tui.writeInPlace(tuiKey, ['· Continuing.', '']);
        return false;
      }
    }
  }

  Future<void> showShuffling() async {
    await tui.write('· Deck is being shuffled...\n'.dim());
  }

  Future<void> showDealingHole(String dealerName) async {
    await tui.write('· $dealerName is dealing cards to players...\n'.dim());
  }

  Future<void> showBlindIncrease() async {
    await tui.write('· The big blind has increased to ${table.bigBlind}!\n');
  }

  Future<void> showPlayerMove(
    Player player,
    BettingMove move,
    ChipsAmount? bet,
  ) async {
    final bool importantMove;
    final String message;
    switch (move) {
      case BettingMove.folded:
        message = '${player.name} folds.';
        importantMove = true;
      case BettingMove.checked:
        message = '${player.name} checks.';
        importantMove = false;
      case BettingMove.allIn:
        message = '${player.name} goes all-in!';
        importantMove = true;
      case BettingMove.called:
        message = '${player.name} calls.';
        importantMove = false;
      case BettingMove.bet:
        message = '${player.name} bets ${player.bet}.';
        importantMove = true;
      case BettingMove.raised:
        message = '${player.name} raises to ${player.bet}.';
        importantMove = true;
    }

    if (importantMove &&
        player is! HumanPlayer &&
        hasActiveHumanPlayerInRound) {
      await tui.waitForAnyKey(withLine: '· $message');
    } else {
      await tui.write('· $message\n'.dim());
    }
  }

  Future<void> showBetBlind(String playerName, String blindSize) async {
    await tui.write('· $playerName bets the $blindSize blind\n'.dim());
  }

  Future<void> showDefaultWinnerFold(
    String playerName,
    ChipsAmount amount,
  ) async {
    await tui.write('· All other players fold.\n');
    await tui.write('· $playerName wins $amount.\n\n');
    await tui.waitForAnyKey();
  }

  Future<void> showDefaultWinnerEligibility(
    String playerName,
    int sidePotNum,
    ChipsAmount amount,
  ) async {
    await tui.write(
      '\n$playerName is the only player eligible for SIDE POT #$sidePotNum.\n',
    );
    await tui.write('$playerName wins $amount.\n\n');
    await tui.waitForAnyKey();
  }

  Future<void> showPhaseChangeAlert(Phase phase, String dealer) async {
    if (phase == Phase.preflop) {
      await tui.write('· Preflop Round: $dealer is the dealer.\n'.dim());
    } else {
      final nameCapitalized =
          phase.name[0].toUpperCase() + phase.name.substring(1);
      await tui.write('· Round Change: the $nameCapitalized.\n'.dim());
    }
  }

  Future<void> showTable({bool isShowdown = false}) async {
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => (b.isInGame ? 1 : 0).compareTo(a.isInGame ? 1 : 0));

    await tui.write('\n');
    await tui.write(
      '${' ' * 12}    ${'HAND'.padRight(12)}   ${'BET'.padLeft(7)}'
              '   ${'CHIPS'.padLeft(7)}   STATUS'
          .dim(),
    );
    await tui.write('\n${('-' * 79).dim()}\n', speedOverride: 1000);
    for (final player in sortedPlayers) {
      final strBuf = StringBuffer();
      strBuf.write(player.name.padLeft(12));
      strBuf.write('    ');

      if (!player.isInGame) {
        strBuf.write('[BUSTED]'.dim());
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

        strBuf.write(player.bet.toString().padLeft(7));

        strBuf.write('   ');

        if (player.isAllIn) {
          strBuf.write(' all-in');
        } else {
          strBuf.write(player.chips.toString().padLeft(7).dim());
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

      await tui.write(
        strBuf.toString(),
        speedOverride: 1000,
        charsPerWrite: 50,
      );
    }
    await tui.write('\n');

    final communityCards = TerminalUI.formatHand(
      table.community,
      showFace: true,
      useColor: useColor,
    );
    await tui.write(
      '${'Community'.padLeft(12)}    $communityCards\n\n',
      speedOverride: 1000,
    );

    await tui.write(
      '${'Small Blind'.padLeft(12)}  '
      '${(table.bigBlind ~/ 2).toString().padLeft(7).dim()}',
      speedOverride: 1000,
    );
    await tui.write('\n', speedOverride: 1000);
    await tui.write(
      '${'Big Blind'.padLeft(12)}  '
      '${table.bigBlind.toString().padLeft(7).dim()}',
      speedOverride: 1000,
    );
    await tui.write('\n', speedOverride: 1000);

    final mainPot = table.pots[0];
    await tui.write(
      '${'POT'.padLeft(12)}  '
      '${mainPot.amount.toString().padLeft(7)}\n',
      speedOverride: 1000,
    );
    for (var i = 1; i < table.pots.length; i++) {
      final sidePot = table.pots[i];
      await tui.write(
        '${'SIDE POT #$i'.padLeft(12)}  '
        '${sidePot.amount.toString().padLeft(7)}\n',
        speedOverride: 1000,
      );
    }
    await tui.write('\n', speedOverride: 1000);
  }

  Future<void> showShowdownResults(
    List<Player> handWinners,
    List<Player> showdownPlayers,
    int potNum,
    ChipsAmount amountPerWinner,
  ) async {
    await showTable(isShowdown: true);
    await showPotWinners(handWinners, showdownPlayers, potNum, amountPerWinner);
  }

  Future<void> showPotWinners(
    List<Player> handWinners,
    List<Player> showdownPlayers,
    int potNum,
    ChipsAmount amountPerWinner,
  ) async {
    var potType = 'the pot';
    if (potNum > 0) {
      potType = 'SIDE POT #$potNum';
      final playersStr = showdownPlayers.map((p) => p.name).join(', ');
      await tui.write(
        '· Players eligible for SIDE POT #$potNum: $playersStr\n',
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
        '· ${winner.name} wins $amountPerWinner '
        'with a $rankStr${winner.rankSubtype}!\n',
      );
      await tui.write('  $handStr\n');
      if (winner.kickerCard != null) {
        final cardStr = TerminalUI.formatCard(
          winner.kickerCard!,
          showFace: true,
          useColor: useColor,
        );
        await tui.write('  Kicker card was the $cardStr.\n');
      }
      await tui.write('\n');
    } else {
      for (var i = 0; i < handWinners.length; i++) {
        final winner = handWinners[i];
        final handStr = TerminalUI.formatHand(
          winner.bestHandCards,
          showFace: true,
          useColor: useColor,
        );
        await tui.write('· ${winner.name} wins $amountPerWinner\n');
        await tui.write('  $handStr\n');
        if (i == handWinners.length - 1) {
          final rankStr = winner.bestHandRank?.description ?? '';
          await tui.write(
            '· Split $potType with a $rankStr${winner.rankSubtype}!\n',
          );
          if (winner.kickerCard != null) {
            await tui.write(
              '  Kicker card was the ${winner.kickerCard!.rank.symbol}\n',
            );
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
      final nameStr = player.name.padLeft(16);
      final chipsStr = player.chips.toString().padLeft(18);
      await tui.write('$nameStr$chipsStr\n');
    }
    await tui.write('\n\n');

    String winnersStr;
    if (winnersNames.length == 1) {
      winnersStr = winnersNames[0];
    } else if (winnersNames.length == 2) {
      winnersStr = '${winnersNames[0]} and ${winnersNames[1]}';
    } else {
      winnersStr =
          '${winnersNames.sublist(0, winnersNames.length - 1).join(', ')},'
          ' and ${winnersNames.last}';
    }
    await tui.write('· $winnersStr wins the game!\n\n\n\n');
    await tui.write('==================================\n');
    await tui.write('             GAME OVER            \n');
    await tui.write('==================================\n\n\n\n');
  }
}

class _QuitException implements Exception {
  const _QuitException();
}
