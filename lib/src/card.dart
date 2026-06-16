import 'package:meta/meta.dart';

class Card {
  final CardRank rank;

  final CardSuite suite;

  @literal
  const Card(this.rank, this.suite);

  @override
  int get hashCode => Object.hash(rank, suite);

  String get symbol {
    return '${rank.symbol.padRight(2, ' ')}${suite.symbol}';
  }

  String get pokerNotation {
    final r = rank == CardRank.r10 ? 'T' : rank.symbol;
    final s = switch (suite) {
      CardSuite.club => 'c',
      CardSuite.diamond => 'd',
      CardSuite.heart => 'h',
      CardSuite.spade => 's',
    };
    return '$r$s';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Card && rank == other.rank && suite == other.suite;
  }

  @override
  String toString() {
    return '${rank.description} of ${suite.description}';
  }
}

enum CardRank {
  r2(2, 'two', '2'),
  r3(3, 'three', '3'),
  r4(4, 'four', '4'),
  r5(5, 'five', '5'),
  r6(6, 'six', '6'),
  r7(7, 'seven', '7'),
  r8(8, 'eight', '8'),
  r9(9, 'nine', '9'),
  r10(10, 'ten', '10'),
  j(11, 'jack', 'J'),
  q(12, 'queen', 'Q'),
  k(13, 'king', 'K'),
  a(14, 'ace', 'A');

  static const CardRank lowest = r2;

  static const CardRank highest = a;

  final int rank;

  final String description;

  final String symbol;

  const CardRank(this.rank, this.description, this.symbol);

  bool operator <(CardRank other) => rank < other.rank;

  bool operator >(CardRank other) => rank > other.rank;
}

enum CardSuite {
  club('club', '♣'),
  diamond('diamond', '♦'),
  heart('heart', '♥'),
  spade('spade', '♠');

  final String description;

  final String symbol;

  const CardSuite(this.description, this.symbol);
}
