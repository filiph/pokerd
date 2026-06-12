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

## Example Dialogue

**Developer**: When evaluating a Full House, do we compare the triplet first?
**Domain Expert**: Yes, the triplet is the primary rank. A Full House of "Kings over Twos" beats "Jacks over Aces". If those are identical (which is impossible with a single standard deck but possible in multi-deck variants), we look at the pair.
**Developer**: What about the **Kicker**? Does a Full House have a kicker?
**Domain Expert**: No, a Full House consists of exactly five cards, so there are no remaining cards to act as kickers. Kickers are only used in categories with fewer than 5 cards of combination, like One Pair, Two Pair, Three of a Kind, Four of a Kind, and High Card.
