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
  });
}
