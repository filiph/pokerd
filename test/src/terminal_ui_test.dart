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

    group('_wrapLine ANSI handling', () {
      test('wraps correctly when ANSI codes are present', () async {
        const width = 10;
        final output = StringBuffer();
        final testTui = TerminalUI(outputSink: output);
        testTui.terminalWidthOverride = width;
        testTui.speed = 0;

        // "RED" in red color. Visible length = 3.
        final redText = '\x1B[31mRED\x1B[0m';
        // Total visible: 3 ("RED") + 1 (" ") + 10 ("1234567890") = 14.
        final line = '$redText 1234567890';

        await testTui.write(line);

        final outputLines = output.toString().trimRight().split('\n');
        final ansiRegex = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

        // Expected:
        // Line 1: "RED 123456" (visible length 10)
        // Line 2: "7890" (visible length 4)

        expect(outputLines.length, equals(2));

        expect(outputLines[0].replaceAll(ansiRegex, '').length, equals(10));
        expect(outputLines[1].replaceAll(ansiRegex, '').length, equals(4));

        expect(outputLines[0].replaceAll(ansiRegex, ''), equals('RED 123456'));
        expect(outputLines[1].replaceAll(ansiRegex, ''), equals('7890'));
      });

      test(
        'wraps correctly when ANSI code is exactly at the wrap point',
        () async {
          const width = 5;
          final output = StringBuffer();
          final testTui = TerminalUI(outputSink: output);
          testTui.terminalWidthOverride = width;
          testTui.speed = 0;

          // 1234[ANSI]5678
          final line = '1234\x1B[31m5678';
          await testTui.write(line);

          final outputLines = output.toString().trimRight().split('\n');
          final ansiRegex = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

          // Expected:
          // Line 1: "1234[ANSI]5" (visible length 5)
          // Line 2: "678" (visible length 3)
          expect(outputLines[0].replaceAll(ansiRegex, ''), equals('12345'));
          expect(outputLines[1].replaceAll(ansiRegex, ''), equals('678'));
        },
      );

      test(
        'wraps correctly when ANSI code is just before the wrap point',
        () async {
          const width = 5;
          final output = StringBuffer();
          final testTui = TerminalUI(outputSink: output);
          testTui.terminalWidthOverride = width;
          testTui.speed = 0;

          // 1234[ANSI] 5678
          final line = '1234\x1B[31m 5678';
          await testTui.write(line);

          final outputLines = output.toString().trimRight().split('\n');
          final ansiRegex = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

          // Expected:
          // Line 1: "1234[ANSI] " (visible length 5)
          // Line 2: "5678" (visible length 4)
          expect(outputLines[0].replaceAll(ansiRegex, ''), equals('1234 '));
          expect(outputLines[1].replaceAll(ansiRegex, ''), equals('5678'));
        },
      );
    });
  });
}
