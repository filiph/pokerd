import 'card.dart';
import 'chips_amount.dart';
import 'betting_move.dart';

class GameEvent {
  final String event;
  final Map<String, dynamic> data;

  GameEvent._(this.event, this.data);

  factory GameEvent.action({
    required String player,
    required BettingMove move,
    required List<Card> playerCards,
    required List<Card> communityCards,
    required double winProb,
    required ChipsAmount pot,
    required ChipsAmount bet,
  }) =>
      GameEvent._('action', {
        'player': player,
        'move': move.name,
        'playerCards': _formatCards(playerCards),
        'communityCards': _formatCards(communityCards),
        'winProb': winProb,
        'pot': pot.value,
        'bet': bet.value,
      });

  factory GameEvent.fold({
    required String player,
    required List<Card> playerCards,
    required List<Card> communityCards,
    required double winProb,
  }) =>
      GameEvent._('fold', {
        'player': player,
        'playerCards': _formatCards(playerCards),
        'communityCards': _formatCards(communityCards),
        'winProb': winProb,
      });

  factory GameEvent.win({
    required String player,
    required List<Card> playerCards,
    required List<Card> communityCards,
    required String hand,
    required String handRank,
    required ChipsAmount pot,
  }) =>
      GameEvent._('win', {
        'player': player,
        'playerCards': _formatCards(playerCards),
        'communityCards': _formatCards(communityCards),
        'hand': hand,
        'handRank': handRank,
        'pot': pot.value,
      });

  factory GameEvent.lose({
    required String player,
    required List<Card> playerCards,
    required List<Card> communityCards,
    required String hand,
    required String handRank,
  }) =>
      GameEvent._('lose', {
        'player': player,
        'playerCards': _formatCards(playerCards),
        'communityCards': _formatCards(communityCards),
        'hand': hand,
        'handRank': handRank,
      });

  factory GameEvent.roundStart({
    required int roundNumber,
    required List<String> players,
  }) =>
      GameEvent._('roundStart', {
        'roundNumber': roundNumber,
        'players': players,
      });

  static String _formatCards(List<Card> cards) =>
      cards.map((c) => c.pokerNotation).join(' ');

  Map<String, dynamic> toJson() => {
        'event': event,
        ...data,
      };
}
