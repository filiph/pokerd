import 'package:tint/tint.dart';

/// Highlights sections of a string enclosed in `[...]`.
///
/// Any text between square brackets that contains one or more non-whitespace,
/// non-bracket characters is styled using the provided [style] function
/// (which defaults to underlining the text).
String ansi(String input, {String Function(String)? style}) {
  final resolvedStyle = style ?? (s) => s.underline();
  final regex = RegExp(r'\[([^\]\s]+)\]');

  return input.replaceAllMapped(regex, (match) {
    final content = match.group(1)!;
    return resolvedStyle(content);
  });
}
