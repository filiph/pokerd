import 'dart:async';
import 'package:pokerd/src/terminal_ui.dart';
import 'package:test/test.dart';

void main() {
  group('InputChar', () {
    test('predefined constants and construction', () {
      expect(InputChar.left.isLeft, isTrue);
      expect(InputChar.right.isRight, isTrue);
      expect(InputChar.up.isUp, isTrue);
      expect(InputChar.down.isDown, isTrue);

      expect(InputChar.keyQ.isQ, isTrue);
      expect(InputChar.keyP.isP, isTrue);

      final qUpper = InputChar.fromChar('Q');
      expect(qUpper.isQ, isTrue);
      expect(qUpper, equals(InputChar.keyQ)); // 'Q' is normalized to keyQ

      final normalX = InputChar.fromChar('x');
      expect(normalX.char, equals('x'));
      expect(normalX.isQ, isFalse);
    });

    test('equality and hashCode', () {
      final a1 = InputChar.fromChar('a');
      final a2 = InputChar.fromChar('a');
      final b = InputChar.fromChar('b');

      expect(a1, equals(a2));
      expect(a1, isNot(equals(b)));
      expect(a1.hashCode, equals(a2.hashCode));
    });
  });

  group('TerminalUI', () {
    late StreamController<List<int>> streamController;
    late TerminalUI terminalUI;

    setUp(() {
      streamController = StreamController<List<int>>();
      terminalUI = TerminalUI(inputStream: streamController.stream);
    });

    tearDown(() {
      terminalUI.dispose();
      streamController.close();
    });

    test('parses normal keys from input stream', () async {
      final futureKey = terminalUI.readKey();
      streamController.add([113]); // 'q'
      final key = await futureKey;
      expect(key, equals(InputChar.keyQ));
    });

    test('parses arrow keys from input stream', () async {
      // Test left arrow
      var futureKey = terminalUI.readKey();
      streamController.add([27, 91, 68]); // ESC [ D
      var key = await futureKey;
      expect(key, equals(InputChar.left));

      // Test right arrow
      futureKey = terminalUI.readKey();
      streamController.add([27, 91, 67]); // ESC [ C
      key = await futureKey;
      expect(key, equals(InputChar.right));
    });

    test(
      'writeInPlace has delay on first write but no delay on rewrite of same key',
      () async {
        terminalUI.speed = 1000; // 1000 cps -> 1 ms per character

        final lines = ['a' * 100]; // 100 characters

        // First write of key 'test' should have delay
        final sw1 = Stopwatch()..start();
        await terminalUI.writeInPlace('test', lines);
        sw1.stop();

        // Second write of key 'test' should not have delay (rewrite)
        final sw2 = Stopwatch()..start();
        await terminalUI.writeInPlace('test', lines);
        sw2.stop();

        expect(
          sw1.elapsedMilliseconds,
          greaterThanOrEqualTo(80),
        ); // Should be ~100ms
        expect(
          sw2.elapsedMilliseconds,
          lessThan(30),
        ); // Should be ~0ms (immediate)
      },
    );

    test('terminalWidth default, override and wrapping logic with write', () async {
      final outputBuffer = StringBuffer();
      final testTui = TerminalUI(
        inputStream: streamController.stream,
        outputSink: outputBuffer,
      );
      testTui.speed = 0; // Disable delay for tests

      // 1. By default terminalWidth should fallback to 80 when not run in a terminal (as in tests)
      expect(testTui.terminalWidth, equals(80));

      // 2. Setting terminalWidthOverride should override terminalWidth
      testTui.terminalWidthOverride = 40;
      expect(testTui.terminalWidth, equals(40));

      // 3. Testing write wrapping with custom width (40)
      final textToWrap = 'a' * 100;
      await testTui.write(textToWrap);

      final outputLines = outputBuffer.toString().split('\n');
      // 100 characters wrapped at 40 width should result in 3 lines: 40, 40, 20
      expect(outputLines, containsAllInOrder(['a' * 40, 'a' * 40, 'a' * 20]));

      outputBuffer.clear();

      // 4. Testing write wrapping with larger custom width (120)
      testTui.terminalWidthOverride = 120;
      await testTui.write(textToWrap);

      final outputLinesLarge = outputBuffer.toString().split('\n');
      // 100 characters wrapped at 120 width should fit on a single line
      expect(outputLinesLarge, contains('a' * 100));
    });

    test('writeInPlace wrapping logic with terminalWidthOverride', () async {
      final outputBuffer = StringBuffer();
      final testTui = TerminalUI(
        inputStream: streamController.stream,
        outputSink: outputBuffer,
      );
      testTui.speed = 0; // Disable delay for tests

      testTui.terminalWidthOverride = 30;

      final lines = ['b' * 75]; // 75 characters
      await testTui.writeInPlace('inplace_test', lines);

      final output = outputBuffer.toString();
      // Since it is 75 chars and wrapped at 30, it should be 3 lines:
      // b * 30 + \n
      // b * 30 + \n
      // b * 15 + \n
      final expectedWrappedOutput = '${'b' * 30}\n${'b' * 30}\n${'b' * 15}\n';
      expect(output, equals(expectedWrappedOutput));
    });
  });
}
