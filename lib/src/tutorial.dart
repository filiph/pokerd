import 'package:pokerd/src/card.dart';
import 'package:pokerd/src/terminal_ui.dart';
import 'package:tint/tint.dart';

Future<void> showRules(TerminalUI tui) async {
  const speedFactor = 10;
  final speed = tui.speed * speedFactor;

  await tui.write('\nINTRODUCTION\n', speedOverride: speed);
  await tui.write(
    'Texas Hold Em is a betting game. Each player receives two private cards.\n'
            'Five community cards are dealt to the center of the table. The goal\n'
            'is to form the best five-card hand using any combination of these\n'
            'seven cards.\n\n'
        .dim(),
    speedOverride: speed,
  );
  await tui.waitForAnyKey(withLine: '(1 / 8)'.dim());
  await tui.write('\n');

  await tui.write('THE DEALER\n', speedOverride: speed);
  await tui.write(
    'One player acts as the dealer for each hand, marked by a dealer button.\n'
            'The dealer acts last in betting rounds. The button moves to the\n'
            'left after each hand.\n\n'
        .dim(),
    speedOverride: speed,
  );
  await tui.waitForAnyKey(withLine: '(2 / 8)'.dim());
  await tui.write('\n');

  await tui.write('THE BLINDS\n', speedOverride: speed);
  await tui.write(
    'The two players to the left of the dealer make forced bets called\n'
            'blinds before seeing their cards. The first player posts the small\n'
            'blind, which is half the minimum bet. The second player posts the\n'
            'big blind, which is the full minimum bet. Blinds increase\n'
            'periodically.\n\n'
        .dim(),
    speedOverride: speed,
  );
  await tui.waitForAnyKey(withLine: '(3 / 8)'.dim());
  await tui.write('\n');

  await tui.write('FIRST ROUND OF BETTING\n', speedOverride: speed);
  await tui.write(
    'After blinds are posted, each player receives two face-down hole\n'
            'cards. The first betting round begins with the player to the left\n'
            'of the big blind.\n\n'
            'During your turn, you can Fold, Call, or Raise. Fold means you\n'
            'withdraw from the hand. Call means you match the current highest\n'
            'bet. Raise means you increase the current bet.\n\n'
            'The minimum bet equals the big blind. There is no upper limit,\n'
            'but you cannot bet more chips than you or your active opponents\n'
            'have. Going All In means betting all your remaining chips.\n\n'
        .dim(),
    speedOverride: speed,
  );
  await tui.waitForAnyKey(withLine: '(4 / 8)'.dim());
  await tui.write('\n');

  await tui.write('SUBSEQUENT ROUNDS\n', speedOverride: speed);
  await tui.write(
    'After the first betting round, three community cards are dealt\n'
            'face-up. This is the Flop. Another betting round occurs, starting\n'
            'with the player to the left of the dealer.\n\n'
            'If no one has bet yet, you can Check, which means passing the\n'
            'action to the next player without betting. If someone bets, you\n'
            'must Call, Raise, or Fold.\n\n'
            'A fourth community card is dealt, called the Turn. Another\n'
            'betting round follows.\n\n'
            'A fifth and final community card is dealt, called the River. A\n'
            'final betting round follows.\n\n'
        .dim(),
    speedOverride: speed,
  );
  await tui.waitForAnyKey(withLine: '(5 / 8)'.dim());
  await tui.write('\n');

  await tui.write('SHOWDOWN\n', speedOverride: speed);
  await tui.write(
    'A hand ends in one of two ways. If all but one player folds, the\n'
            'remaining player wins the pot and does not have to show their\n'
            'cards.\n\n'
            'If multiple players remain after the final betting round, a\n'
            'showdown occurs. Players reveal their hole cards. The player with\n'
            'the best five-card hand wins the pot.\n\n'
        .dim(),
    speedOverride: speed,
  );
  await tui.waitForAnyKey(withLine: '(6 / 8)'.dim());
  await tui.write('\n');

  await tui.write('HAND RANKINGS\n', speedOverride: speed);
  await tui.write(
    'You can view the hand rankings any time during play by navigating\n'
            'to the Options menu and selecting Help.\n\n'
        .dim(),
    speedOverride: speed,
  );
  await tui.waitForAnyKey(withLine: '(7 / 8)'.dim());
  await tui.write('\n');

  await tui.write('STRATEGY\n', speedOverride: speed);
  await tui.write(
    'When you have the basics down, you can read up on some beginner\n'
            'strategies, such as the "rule of 4 and 2".\n\n'
            'Here\'s a short article to get you started:\n'
            'https://www.poker.org/poker-strategy/how-to-play-texas-holdem/\n\n'
        .dim(),
    speedOverride: speed,
  );
  await tui.write('(8 / 8)\n\n'.dim());
}

Future<void> showRankingsHelp(TerminalUI tui, {bool useColor = false}) async {
  await tui.write('\nHand Rankings:\n\n');

  final List<(String, List<Card>, String)> rankings = const [
    (
      'Royal Flush',
      [
        Card(CardRank.a, CardSuite.spade),
        Card(CardRank.k, CardSuite.spade),
        Card(CardRank.q, CardSuite.spade),
        Card(CardRank.j, CardSuite.spade),
        Card(CardRank.r10, CardSuite.spade),
      ],
      '0.00015%',
    ),
    (
      'Straight Flush',
      [
        Card(CardRank.r9, CardSuite.heart),
        Card(CardRank.r8, CardSuite.heart),
        Card(CardRank.r7, CardSuite.heart),
        Card(CardRank.r6, CardSuite.heart),
        Card(CardRank.r5, CardSuite.heart),
      ],
      '0.0014%',
    ),
    (
      'Four of a Kind',
      [
        Card(CardRank.r7, CardSuite.spade),
        Card(CardRank.r7, CardSuite.heart),
        Card(CardRank.r7, CardSuite.diamond),
        Card(CardRank.r7, CardSuite.club),
      ],
      '0.024%',
    ),
    (
      'Full House',
      [
        Card(CardRank.k, CardSuite.spade),
        Card(CardRank.k, CardSuite.heart),
        Card(CardRank.k, CardSuite.diamond),
        Card(CardRank.q, CardSuite.spade),
        Card(CardRank.q, CardSuite.heart),
      ],
      '0.14%',
    ),
    (
      'Flush',
      [
        Card(CardRank.k, CardSuite.diamond),
        Card(CardRank.r10, CardSuite.diamond),
        Card(CardRank.r8, CardSuite.diamond),
        Card(CardRank.r7, CardSuite.diamond),
        Card(CardRank.r5, CardSuite.diamond),
      ],
      '0.20%',
    ),
    (
      'Straight',
      [
        Card(CardRank.r10, CardSuite.spade),
        Card(CardRank.r9, CardSuite.heart),
        Card(CardRank.r8, CardSuite.diamond),
        Card(CardRank.r7, CardSuite.club),
        Card(CardRank.r6, CardSuite.spade),
      ],
      '0.39%',
    ),
    (
      'Three of a Kind',
      [
        Card(CardRank.r7, CardSuite.spade),
        Card(CardRank.r7, CardSuite.heart),
        Card(CardRank.r7, CardSuite.diamond),
      ],
      '2.11%',
    ),
    (
      'Two Pair',
      [
        Card(CardRank.j, CardSuite.spade),
        Card(CardRank.j, CardSuite.heart),
        Card(CardRank.r5, CardSuite.diamond),
        Card(CardRank.r5, CardSuite.club),
      ],
      '4.75%',
    ),
    (
      'One Pair',
      [Card(CardRank.r6, CardSuite.spade), Card(CardRank.r6, CardSuite.heart)],
      '42.26%',
    ),
    ('High Card', [Card(CardRank.r10, CardSuite.spade)], '50.12%'),
  ];

  await tui.write(
    '${' ' * 4}  ${'NAME'.padRight(15)}   '
    '${'EXAMPLE HAND'.padRight(29)}   ODDS\n',
  );
  // await tui.write('=' * 79 + '\n', speedOverride: 1000);
  for (var i = 0; i < rankings.length; i++) {
    final rank = rankings[i];

    final strBuf = StringBuffer();
    for (var cardIndex = 0; cardIndex < 5; cardIndex++) {
      if (cardIndex >= rank.$2.length) {
        strBuf.write('[···]'.dim());
      } else {
        final card = rank.$2[cardIndex];
        strBuf.write(
          TerminalUI.formatCard(card, showFace: true, useColor: useColor),
        );
      }

      if (cardIndex < 4) {
        strBuf.write(' ');
      }
    }

    await tui.write(
      '${'#${i + 1}'.toString().padLeft(4)}  '
      '${rank.$1.padRight(15)}   '
      '${strBuf.toString()}   '
      '${rank.$3}\n',
      speedOverride: 1000,
    );
  }
}
