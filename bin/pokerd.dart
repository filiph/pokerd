import 'package:args/args.dart';
import 'package:pokerd/src/ansi.dart';
import 'package:pokerd/src/game.dart';
import 'package:pokerd/src/terminal_ui.dart';
import 'package:pokerd/src/tutorial.dart';
import 'package:tint/tint.dart';

const String version = '0.0.1';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.');
}

void printUsage(ArgParser argParser) {
  print('Usage: dart pokerd.dart <flags> [arguments]');
  print(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    bool verbose = false;

    // Process the parsed arguments.
    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
    if (results.flag('version')) {
      print('pokerd version: $version');
      return;
    }
    if (results.flag('verbose')) {
      verbose = true;
    }

    if (verbose) {
      print('[VERBOSE] All arguments: ${results.arguments}');
    }

    final tui = TerminalUI();
    try {
      await tui.write('Welcome to pokerd.\n');
      await tui.write('A Texas Hold’em game in your terminal.\n\n'.dim());

      bool running = true;
      while (running) {
        await tui.writeInPlace('menu', [
          ansi(
            '${'●'.green()}   [S]tart tournament   [R]ules   [A]bout   [Q]uit',
          ),
        ]);

        final key = await tui.readKey();

        if (key.isS) {
          await tui.write('\n· Starting tournament...\n'.dim());
          final game = Game(tui);
          await game.play();
        } else if (key.isR) {
          await showRules(tui);
        } else if (key.isA) {
          await tui.write('\n');
          await tui.write(
            '· Poker is a game from the late 18th century. It was inspired by\n'
                    '  the French game of poque and possibly the Persian game of As-Nas,\n'
                    '  and originated in the American South.\n'
                .dim(),
            speedOverride: 1000,
            charsPerWrite: 30,
          );
          await tui.write(
            '· Texas Hold\'em is a variant that was invented in Robstown,\n'
                    '  a small town in Texas, in the early 20th century. It was later\n'
                    '  popularized in Las Vegas after it had been brought there in 1967.\n'
                .dim(),
            speedOverride: 1000,
            charsPerWrite: 30,
          );
          await tui.write(
            '· This project is meant as a Texas Hold\'em "trainer" for beginner players.\n'
                    '  It\'s a sandbox for trying out strategies and building an intuition\n'
                    '  for the probabilities involved in poker.\n'
                .dim(),
            speedOverride: 1000,
            charsPerWrite: 30,
          );
          await tui.write(
            '· The implementation is heavily inspired by Quincy Elery\'s Python project:\n'
                    '  https://github.com/qelery/Command-Line-Poker\n\n'
                .dim(),
            speedOverride: 1000,
            charsPerWrite: 30,
          );
          await tui.write(
            '· Made by Filip Hracek, a non-immersive games enthusiast.\n'.dim(),
            speedOverride: 1000,
            charsPerWrite: 30,
          );
          await tui.write('  https://filiph.net/\n\n\n');
        } else if (key.isQ) {
          await tui.write('\nGood bye.\n');
          running = false;
        }
      }
    } finally {
      tui.dispose();
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}
