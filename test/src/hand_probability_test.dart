import 'package:pokerd/src/card.dart';
import 'package:pokerd/src/hand_rank.dart';
import 'package:test/test.dart';

void main() {
  group('HandRank.estimateWinProbability', () {
    test('strong hand has high probability', () {
      final myHand = [
        const Card(CardRank.a, CardSuite.spade),
        const Card(CardRank.a, CardSuite.heart),
      ];
      final community = [
        const Card(CardRank.a, CardSuite.diamond),
        const Card(CardRank.k, CardSuite.diamond),
        const Card(CardRank.q, CardSuite.diamond),
      ];
      final prob = HandRank.estimateWinProbability(
        myHand,
        community,
        1,
        iterations: 1000,
      );
      expect(prob, greaterThan(0.8));
    });

    test('weak hand has low probability', () {
      final myHand = [
        const Card(CardRank.r2, CardSuite.spade),
        const Card(CardRank.r7, CardSuite.heart),
      ];
      final community = [
        const Card(CardRank.a, CardSuite.diamond),
        const Card(CardRank.k, CardSuite.diamond),
        const Card(CardRank.q, CardSuite.diamond),
      ];
      final prob = HandRank.estimateWinProbability(
        myHand,
        community,
        3,
        iterations: 1000,
      );
      expect(prob, lessThan(0.2));
    });
  });
}
