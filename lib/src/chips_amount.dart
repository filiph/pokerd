import 'package:meta/meta.dart';

@immutable
class ChipsAmount implements Comparable<ChipsAmount> {
  final int value;

  @literal
  const ChipsAmount(this.value);

  ChipsAmount operator +(ChipsAmount other) => ChipsAmount(value + other.value);
  ChipsAmount operator -(ChipsAmount other) => ChipsAmount(value - other.value);
  ChipsAmount operator *(num other) => ChipsAmount((value * other).round());
  ChipsAmount operator ~/(int other) => ChipsAmount(value ~/ other);
  ChipsAmount operator %(int other) => ChipsAmount(value % other);

  ChipsAmount abs() => ChipsAmount(value.abs());

  bool operator <(ChipsAmount other) => value < other.value;
  bool operator >(ChipsAmount other) => value > other.value;
  bool operator <=(ChipsAmount other) => value <= other.value;
  bool operator >=(ChipsAmount other) => value >= other.value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChipsAmount &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  int compareTo(ChipsAmount other) => value.compareTo(other.value);

  @override
  String toString() {
    return '\$${formatWithCommas(value)}';
  }

  static String formatWithCommas(int value) {
    String str = value.toString();
    if (str.length <= 3) return str;

    final buffer = StringBuffer();
    int firstComma = str.length % 3;
    if (firstComma == 0) firstComma = 3;

    buffer.write(str.substring(0, firstComma));
    for (int i = firstComma; i < str.length; i += 3) {
      buffer.write(',');
      buffer.write(str.substring(i, i + 3));
    }
    return buffer.toString();
  }
}
