import 'dart:collection';

import 'package:logging/logging.dart';

import 'card.dart';

class Deck {
  static final Logger _log = Logger('$Deck');

  List<Card> _cards = [];

  Deck() {
    refill();
  }

  UnmodifiableListView<Card> get cards => UnmodifiableListView(_cards);

  void burn() {
    if (_cards.isNotEmpty) {
      final removedCard = _cards.removeLast();
      _log.fine('Burning a card: ${removedCard.symbol}');
    } else {
      _log.fine('Tried to burn a card but the deck is empty');
    }
  }

  List<Card> deal(int n) {
    final result = List.generate(n, (_) => _cards.removeLast());
    _log.fine(
      'Dealing $n cards: ${result.map((card) => card.symbol).join(', ')}',
    );
  }

  void refill() {
    _log.fine('Refilling deck');
    _cards = [
      for (final suite in CardSuite.values)
        for (final rank in CardRank.values) Card(rank, suite),
    ];
  }

  void shuffle() {
    _log.fine('Shuffling deck');
    _cards.shuffle();
  }

  @override
  String toString() {
    return _cards.map((card) => '[${card.symbol}]').join(' ');
  }
}
