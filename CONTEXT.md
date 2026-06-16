# Poker Domain

This context covers the core logic of evaluating card values, hand rankings, and resolving showdowns in Texas Hold'em.

## Language

**Card**:
A standard playing card defined by its **CardRank** and **CardSuite**.

**CardRank**:
The numerical value of a card, ranging from 2 (two) to 14 (ace).

**CardSuite**:
The suit of a card, which is one of Spade, Heart, Diamond, or **Club**.
_Avoid_: Cross

**Club**:
The suit representing clubs.
_Avoid_: Cross

**HandRank**:
A structured representation of the standard 10 poker hand categories, ordered from High Card to Royal Flush.
_Avoid_: Hand category, Rank string

**Kicker**:
An extra card that does not directly form part of a hand combination but is used as a tie-breaker when players have hands of the same **HandRank** and score.

**Showdown**:
The final stage of a hand where active players reveal their cards and compare them using **HandRank** and **Kicker**s to determine the winner(s).

## Why we're not using package:poker

As of 2026-06-16, we have decided not to integrate `package:poker` for hand evaluation. Our investigation revealed that its evaluator is unreliable; specifically, it misidentifies an Ace-high straight (e.g., `Ah Ks Qd Jc Th`) as "Quads" (four of a kind).

However, the package offers several features that may be valuable for future implementation:
- **Poker Range Parsing**: Capability to parse standard poker notation (e.g., `HandRange.parse("AQs-ATs, 44+")`), which our project currently lacks. (Note: The `Card` class now has a `pokerNotation` getter that outputs standard notation like 'Ah' or 'Td').
- **Efficient Core Models**: Bitmask-based representations like `ImmutableCardSet` and `Card` indices that could significantly improve the performance of our simulation logic.

## Tools

### self_play.dart
A command line tool (`tool/self_play.dart`) that allows running automated poker tournaments between computer players.
It outputs a JSONL stream of events, which is designed to be consumed by an LLM to help with game balancing and NPC AI tweaking.
The tool tracks statistics such as total games played, active games, and wins for each player.

## Example Dialogue

**Developer**: When evaluating a Full House, do we compare the triplet first?
**Domain Expert**: Yes, the triplet is the primary rank. A Full House of "Kings over Twos" beats "Jacks over Aces". If those are identical (which is impossible with a single standard deck but possible in multi-deck variants), we look at the pair.
**Developer**: What about the **Kicker**? Does a Full House have a kicker?
**Domain Expert**: No, a Full House consists of exactly five cards, so there are no remaining cards to act as kickers. Kickers are only used in categories with fewer than 5 cards of combination, like One Pair, Two Pair, Three of a Kind, Four of a Kind, and High Card.
