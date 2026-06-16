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
          ansi('${'●'.green()}   [S]tart tournament   [R]ules   [Q]uit'),
        ]);

        final key = await tui.readKey();

        if (key.isS) {
          await tui.write('\n· Starting tournament...\n'.dim());
          final game = Game(tui);
          await game.play();
        } else if (key.isR) {
          await showRules(tui);
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
