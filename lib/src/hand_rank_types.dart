part of 'hand_rank.dart';

class Flush extends HandRank {
  const Flush() : super(6, 'Flush');
}

class FourOfAKind extends HandRank {
  const FourOfAKind() : super(8, 'Four of a Kind');
}

class FullHouse extends HandRank {
  const FullHouse() : super(7, 'Full House');
}

class HighCard extends HandRank {
  const HighCard() : super(1, 'High Card');
}

class OnePair extends HandRank {
  const OnePair() : super(2, 'One Pair');
}

class RoyalFlush extends HandRank {
  const RoyalFlush() : super(10, 'Royal Flush');
}

class Straight extends HandRank {
  const Straight([String description = 'Straight']) : super(5, description);
}

class WheelStraight extends Straight {
  const WheelStraight() : super('Wheel Straight');
}

class StraightFlush extends HandRank {
  const StraightFlush([String description = 'Straight Flush']) : super(9, description);
}

class WheelStraightFlush extends StraightFlush {
  const WheelStraightFlush() : super('Wheel Straight Flush');
}

class ThreeOfAKind extends HandRank {
  const ThreeOfAKind() : super(4, 'Three of a Kind');
}

class TwoPair extends HandRank {
  const TwoPair() : super(3, 'Two Pair');
}
