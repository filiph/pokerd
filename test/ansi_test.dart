import 'package:pokerd/src/ansi.dart';
import 'package:test/test.dart';

void main() {
  group('ansi utility', () {
    test('unmodified string when no brackets exist', () {
      expect(ansi('Hello world'), equals('Hello world'));
    });

    test('single character highlight with default style', () {
      final result = ansi('[Q]uit');
      // The output should be modified, not contain [Q], and have the letter Q styled.
      expect(result, isNot(contains('[Q]')));
      expect(result, contains('uit'));
      expect(result, contains('Q'));
    });

    test('single character highlight with custom style', () {
      final result = ansi('[Q]uit', style: (s) => '*$s*');
      expect(result, equals('*Q*uit'));
    });

    test('multiple highlights in a single string with custom style', () {
      final result = ansi('[P]lay, [Q]uit, [←] [→]', style: (s) => '*$s*');
      expect(result, equals('*P*lay, *Q*uit, *←* *→*'));
    });

    test(
      'multiple character highlight like [space] or [esc] with custom style',
      () {
        final result = ansi(
          'Press [space] or [esc] to continue',
          style: (s) => '*$s*',
        );
        expect(result, equals('Press *space* or *esc* to continue'));
      },
    );

    test('unmodified for empty brackets []', () {
      expect(ansi('Hello [] world'), equals('Hello [] world'));
    });

    test('unmodified for brackets containing only spaces [ ]', () {
      expect(ansi('Hello [ ] world'), equals('Hello [ ] world'));
    });
  });
}
