import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ansi_escapes/ansi_escapes.dart';
import 'package:pokerd/src/ansi.dart';
import 'package:tint/tint.dart';

import 'card.dart';

enum SpecialKey { left, right, up, down }

class InputChar {
  final String? char;
  final SpecialKey? special;

  const InputChar.char(this.char) : special = null;
  const InputChar.special(this.special) : char = null;

  static const left = InputChar.special(SpecialKey.left);
  static const right = InputChar.special(SpecialKey.right);
  static const up = InputChar.special(SpecialKey.up);
  static const down = InputChar.special(SpecialKey.down);

  static const keyQ = InputChar.char('q');
  static const keyP = InputChar.char('p');

  factory InputChar.fromChar(String char) {
    final lower = char.toLowerCase();
    if (lower == 'q') return keyQ;
    if (lower == 'p') return keyP;
    return InputChar.char(char);
  }

  bool get isLeft => special == SpecialKey.left;
  bool get isRight => special == SpecialKey.right;
  bool get isUp => special == SpecialKey.up;
  bool get isDown => special == SpecialKey.down;
  bool get isP => char?.toLowerCase() == 'p';
  bool get isQ => char?.toLowerCase() == 'q';
  bool get isS => char?.toLowerCase() == 's';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InputChar && other.char == char && other.special == special;
  }

  @override
  int get hashCode => Object.hash(char, special);

  @override
  String toString() {
    if (special != null) {
      return 'InputChar.${special!.name}';
    }
    return "InputChar.char('$char')";
  }
}

class TerminalUI {
  static final _ansiRegex = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
  static const defaultCharsPerWrite = 10;

  final Stream<List<int>> _inputStream;
  final StringSink _outputSink;
  String? _activeKey;
  int _activePhysicalLines = 0;
  int speed = 300; // Characters per second
  int? terminalWidthOverride;

  StreamSubscription<List<int>>? _stdinSub;
  final _inputController = StreamController<InputChar>.broadcast();
  bool _rawModeEnabled = false;

  TerminalUI({Stream<List<int>>? inputStream, StringSink? outputSink})
    : _inputStream = inputStream ?? stdin,
      _outputSink = outputSink ?? stdout;

  int get terminalWidth {
    if (terminalWidthOverride != null) {
      return terminalWidthOverride!;
    }
    try {
      if (stdout.hasTerminal) {
        return stdout.terminalColumns;
      }
    } catch (_) {
      // Safe fallback if stdout.hasTerminal or stdout.terminalColumns throws
    }
    return 80;
  }

  List<String> _wrapLine(String line, int width) {
    if (line.isEmpty) return [''];
    final List<String> chunks = [];

    int currentVisibleWidth = 0;
    int start = 0;

    for (int i = 0; i < line.length; i++) {
      // Check for ANSI escape sequence
      if (line.codeUnitAt(i) == 27 &&
          i + 1 < line.length &&
          line[i + 1] == '[') {
        final match = _ansiRegex.matchAsPrefix(line, i);
        if (match != null) {
          i = match.end - 1; // Skip the ANSI sequence
          continue;
        }
      }

      currentVisibleWidth++;
      if (currentVisibleWidth == width) {
        chunks.add(line.substring(start, i + 1));
        start = i + 1;
        currentVisibleWidth = 0;
      }
    }

    if (start < line.length) {
      chunks.add(line.substring(start));
    } else if (chunks.isEmpty) {
      chunks.add('');
    }

    return chunks;
  }

  Future<void> write(
    String text, {
    int? speedOverride,
    int? charsPerWrite,
  }) async {
    charsPerWrite = charsPerWrite ?? defaultCharsPerWrite;

    _activeKey = null;
    _activePhysicalLines = 0;

    final lines = text.split('\n');
    final hasTrailingNewline = text.endsWith('\n');
    if (hasTrailingNewline && lines.isNotEmpty && lines.last.isEmpty) {
      lines.removeLast();
    }

    final wrapped = <String>[];
    final width = terminalWidth;
    for (final line in lines) {
      wrapped.addAll(_wrapLine(line, width));
    }

    final output = wrapped.join('\n') + (hasTrailingNewline ? '\n' : '');

    final speed = speedOverride ?? this.speed;
    int delay = 0;
    if (speed > 0) {
      delay = (1000 / speed * charsPerWrite).round();
    }

    for (var i = 0; i < output.length; i += charsPerWrite) {
      if (i > 0) await Future<void>.delayed(Duration(milliseconds: delay));
      _outputSink.write(
        output.substring(i, min(i + charsPerWrite, output.length)),
      );
    }
  }

  Future<void> writeInPlace(String key, List<String> lines) async {
    final isRewrite = _activeKey == key && _activePhysicalLines > 0;
    if (isRewrite) {
      _outputSink.write(ansiEscapes.cursorUp(1));
      _outputSink.write(ansiEscapes.eraseLines(_activePhysicalLines));
    } else {
      _activeKey = key;
      _activePhysicalLines = 0;
    }

    final wrapped = <String>[];
    final width = terminalWidth;
    for (final line in lines) {
      wrapped.addAll(_wrapLine(line, width));
    }

    _activePhysicalLines = wrapped.length;
    _activeKey = key;

    final output = wrapped.map((l) => '$l\n').join();

    if (isRewrite) {
      _outputSink.write(output);
    } else {
      const charsPerWrite = 4;
      int delay = 0;
      if (speed > 0) {
        delay = (1000 / speed * charsPerWrite).round();
      }

      for (var i = 0; i < output.length; i += charsPerWrite) {
        _outputSink.write(
          output.substring(i, min(i + charsPerWrite, output.length)),
        );
        await Future<void>.delayed(Duration(milliseconds: delay));
      }
    }
  }

  void _startListening() {
    if (_stdinSub != null) return;

    if (identical(_inputStream, stdin)) {
      try {
        stdin.lineMode = false;
        stdin.echoMode = false;
        _rawModeEnabled = true;
      } catch (_) {
        // Safe fallback in non-interactive environments (e.g. IDE tests)
      }
    }

    final List<int> buffer = [];
    _stdinSub = _inputStream.listen((List<int> bytes) {
      buffer.addAll(bytes);
      _processBuffer(buffer);
    });
  }

  void _processBuffer(List<int> buffer) {
    while (buffer.isNotEmpty) {
      if (buffer[0] == 27) {
        if (buffer.length >= 3 && buffer[1] == 91) {
          final code = buffer[2];
          InputChar? key;
          if (code == 65) key = InputChar.up;
          if (code == 66) key = InputChar.down;
          if (code == 67) key = InputChar.right;
          if (code == 68) key = InputChar.left;

          if (key != null) {
            _inputController.add(key);
            buffer.removeRange(0, 3);
            continue;
          }
        }

        if (buffer.length < 3) {
          break;
        }

        _inputController.add(
          InputChar.fromChar(String.fromCharCode(buffer[0])),
        );
        buffer.removeAt(0);
      } else {
        final charCode = buffer[0];
        final charStr = String.fromCharCode(charCode);
        _inputController.add(InputChar.fromChar(charStr));
        buffer.removeAt(0);
      }
    }
  }

  Future<InputChar> readKey() async {
    _startListening();

    final completer = Completer<InputChar>();
    late StreamSubscription<InputChar> sub;
    sub = _inputController.stream.listen((key) {
      completer.complete(key);
      sub.cancel();
    });

    return completer.future;
  }

  Future<void> waitForAnyKey({String? withLine}) async {
    if (withLine == null) {
      await writeInPlace('__any_key', [ansi('● Press [any] key.').dim()]);
      await readKey();
      await writeInPlace('__any_key', const []);
      return;
    }

    final inPlaceKey = '__any_key_${withLine.hashCode}';
    await writeInPlace(inPlaceKey, [
      '$withLine   ${ansi('Press [any] key.').dim()}',
    ]);
    await readKey();
    await writeInPlace(inPlaceKey, [withLine]);
  }

  void dispose() {
    _stdinSub?.cancel();
    _stdinSub = null;
    _inputController.close();

    if (_rawModeEnabled) {
      try {
        stdin.lineMode = true;
        stdin.echoMode = true;
      } catch (_) {}
      _rawModeEnabled = false;
    }
  }

  static String formatCard(
    Card card, {
    required bool showFace,
    required bool useColor,
  }) {
    if (!showFace) {
      return '[###]';
    }

    final suiteStr = card.suite.symbol;
    late final String coloredSuite = switch (card.suite) {
      .club => suiteStr.green(),
      .diamond => suiteStr.cyan(),
      .heart => suiteStr.red(),
      .spade => suiteStr.yellow(),
    };
    return '[${card.rank.symbol.padRight(2, ' ')}'
        '${useColor ? coloredSuite : suiteStr}]';
  }

  static String formatHand(
    List<Card> hand, {
    required bool showFace,
    required bool useColor,
    bool empty = false,
    int highlightCount = 100000,
  }) {
    const separator = '  ';

    if (empty) {
      return '${' ' * 5}$separator${' ' * 5}';
    }

    final strBuf = StringBuffer();

    for (var i = 0; i < hand.length; i++) {
      final card = hand[i];
      final cardStr = formatCard(card, showFace: showFace, useColor: useColor);

      if (showFace && i < highlightCount) {
        strBuf.write(cardStr);
      } else {
        strBuf.write(cardStr.dim());
      }

      if (i < hand.length - 1) {
        strBuf.write(separator);
      }
    }

    return strBuf.toString();
  }
}
