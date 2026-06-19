### Tournament Log Analysis Report: Baseline (Run 3) vs. Optimal (Run 4) vs. Noisy (Run 5) vs. Tuned (Run 6)

This report provides a comprehensive comparative analysis of four poker tournament runs, each consisting of **50 tournaments** and a cap of **50 max rounds per tournament**. 

The log files analyzed are:
- **Run 3**: `temp_output_filip3.jsonl` (1,021 total rounds) — Baseline with earlier code configurations.
- **Run 4**: `temp_output_filip4.jsonl` (1,000 total rounds) — No error/jitter, refined NPC logic.
- **Run 5**: `temp_output_filip5_with_error.jsonl` (1,025 total rounds) — Active error jitter applied to the NPC players in `lib/src/computer_player.dart` (Grandma: 0.1, Kyle: 0.2, Mr. Case: 0.1, Michelle: 0.05).
- **Run 6**: `temp_output_filip6_tuned.jsonl` (1,044 total rounds) — Tuned Low Flat Jitter strategy with scaled-down error rates (Grandma: 0.03, Kyle: 0.05, Mr. Case: 0.03, Michelle: 0.01).

---

### 1. Overall Tournament Standings

The table below shows the placement of each player across the 50 tournaments for all four runs. 
- **1st Place**: Sole Winner of the tournament
- **4th Place**: First player eliminated (last place)

| Player | Run | 1st Place (Winner) | 2nd Place | 3rd Place | 4th Place (First Out) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Grandma** | **Run 3** | 13 (26%) | 29 (58%) | 8 (16%) | **0 (0%)** |
| | **Run 4** | 9 (18%) | 32 (64%) | 8 (16%) | **1 (2%)** |
| | **Run 5** | **12 (24%)** | 32 (64%) | 6 (12%) | **0 (0%)** |
| | **Run 6** | **17 (34%)** | 28 (56%) | 5 (10%) | **0 (0%)** |
| **Kyle** | **Run 3** | 14 (28%) | 6 (12%) | 8 (16%) | **22 (44%)** |
| | **Run 4** | **18 (36%)** | 3 (6%) | 13 (26%) | **16 (32%)** |
| | **Run 5** | **16 (32%)** | 4 (8%) | 11 (22%) | **19 (38%)** |
| | **Run 6** | **13 (26%)** | 6 (12%) | 16 (32%) | **15 (30%)** |
| **Michelle** | **Run 3** | 9 (18%) | 9 (18%) | 18 (36%) | 14 (28%) |
| | **Run 4** | **16 (32%)** | 9 (18%) | 15 (30%) | **10 (20%)** |
| | **Run 5** | 12 (24%) | 6 (12%) | 16 (32%) | **16 (32%)** |
| | **Run 6** | 8 (16%) | 8 (16%) | 17 (34%) | **17 (34%)** |
| **Mr. Case** | **Run 3** | 14 (28%) | 6 (12%) | 16 (32%) | 14 (28%) |
| | **Run 4** | 7 (14%) | 6 (12%) | 14 (28%) | **23 (46%)** |
| | **Run 5** | **10 (20%)** | 8 (16%) | 17 (34%) | **15 (30%)** |
| | **Run 6** | **12 (24%)** | 8 (16%) | 12 (24%) | **18 (36%)** |

---

### 2. Player Performance Profiles & Error Rate Analysis

Introducing random error jitter in `lib/src/computer_player.dart` had fascinating, asymmetric consequences on the player profiles. The jitter acts as an addition or subtraction of up to `error` to the computed win probability (e.g., `winProb = (winProb + jitter).clamp(0.0, 1.0)`). 

#### 👵 Grandma — "The Ultra-Tight Survivor" (Error Jitter: 0.1 -> 0.03)
- **Behavioral Summary**: Grandma is normally risk-averse, folding early and survival-oriented.
- **Run 5 Impact (Error: 0.1)**:
  - **Survival Rate**: Undefeated! She was eliminated first in **0 out of 50 tournaments**, returning to her perfect survival baseline.
  - **Tournament Wins**: Increased from 9 in Run 4 to **12 in Run 5**.
  - **Active Win Rate**: Rose from 27.10% to **29.02%** (294 wins out of 1013 active rounds).
  - **Analysis**: The ±0.1 error jitter injected occasional "irrational courage" into her play. When positive jitter pushed her perceived win probability above her strict thresholds, she bet or called instead of folding. This mild increase in aggression helped her win more showdowns and convert more 2nd-place finishes into outright tournament victories, without compromising her core survival mechanism.
- **Run 6 Impact (Tuned: 0.03)**:
  - **Survival Rate**: Perfect! Back to **0 out of 50 tournaments** first-outs.
  - **Tournament Wins**: Increased dramatically to a table-leading **17 wins (34%)**.
  - **Active Win Rate**: Rose even higher to **33.17%** (344 wins out of 1037 active rounds).
  - **Analysis**: Tuning Grandma's error rate down to 0.03 hit the perfect sweet spot. It was enough to occasionally force her into active calling and betting lines when positive jitter favored her math, helping her accumulate chips and secure 1st place victories, while maintaining her impenetrable baseline defensive posture.

#### 🕶️ Kyle — "The Loose-Aggressive Chaos" (Error Jitter: 0.2 -> 0.05)
- **Behavioral Summary**: Kyle is a boom-or-bust player, rarely folding preflop and betting aggressively.
- **Run 5 Impact (Error: 0.2)**:
  - **Tournament Wins**: Dropped from 18 in Run 4 to **16 in Run 5**.
  - **Volatility**: 4th place first-outs rose from 16 back up to **19**.
  - **Folds Preflop**: Spiked from 2 folds in Run 4 to **44 folds in Run 5**!
  - **Analysis**: Kyle was assigned the highest error rate (0.2). This massive noise led to highly erratic play. When negative jitter dragged down his perceived win probability, he folded preflop 44 times—a massive change for a player who previously never folded. Conversely, positive jitter drove him to make reckless calls. While he remained a dominant winner due to his raw post-flop aggression, the extreme noise increased his rate of early elimination.
- **Run 6 Impact (Tuned: 0.05)**:
  - **Tournament Wins**: Settled at a strong **13 wins (26%)**.
  - **Folds Preflop**: Dropped from 44 preflop folds in Run 5 to **only 5 preflop folds** in Run 6!
  - **First Outs**: Stable at **15 (30%)** (comparable to Run 4's 16).
  - **Analysis**: Lowering Kyle's error to 0.05 successfully corrected the erratic preflop folding behavior that plagued him in Run 5. He returned to being a highly aggressive, loose maniac with a very realistic but slightly unpredictable profile.

#### 🧠 Michelle — "The Balanced Powerhouse" (Error Jitter: 0.05 -> 0.01)
- **Behavioral Summary**: Michelle is highly balanced, adaptive, and mathematically optimal.
- **Run 5 Impact (Error: 0.05)**:
  - **Tournament Wins**: Dropped from 16 in Run 4 to **12 in Run 5**.
  - **Active Win Rate**: Fell sharply from 52.44% to **44.16%** (306 wins out of 693 active rounds).
  - **First Outs**: Increased from 10 to **16**.
  - **Analysis**: Even a tiny error jitter of 0.05 severely disrupted Michelle's optimal logic. Her strategy depends on precise threshold cutoffs. The added noise caused her to fold strong hands or overplay weak ones, illustrating that highly optimized mathematical models are highly sensitive to noise.
- **Run 6 Impact (Tuned: 0.01)**:
  - **Tournament Wins**: Dropped to **8 wins (16%)**.
  - **First Outs**: Spiked to **17 (34%)**.
  - **Analysis**: Even a minuscule error rate of 0.01 was enough to slightly alter Michelle's extremely fine-tuned, optimal mathematical model. This caused her to play slightly suboptimally compared to her flawless Run 4, showing that a balanced, threshold-heavy style is highly sensitive to even the smallest decision noise.

#### 💼 Mr. Case — "The Underdog Beneficiary" (Error Jitter: 0.1 -> 0.03)
- **Behavioral Summary**: Mr. Case relies strictly on mathematical pot odds, which historically made him too tight and passive preflop.
- **Run 5 Impact (Error: 0.1)**:
  - **Tournament Wins**: Rose from 7 in Run 4 to **10 in Run 5**.
  - **First Outs**: Dropped significantly from 23 (46%) to **15 (30%)**.
  - **Active Games & Win Rate**: Active games rose from 617 to **735**, and his active win rate jumped from 37.28% to **45.44%**!
  - **Analysis**: Mr. Case was the biggest winner from the error injection. His baseline pot odds strategy was previously far too restrictive, causing him to fold too often and get blinded out. The ±0.1 jitter acted as a pseudo-bluffing mechanism, forcing him to play more hands and assert more post-flop pressure. This made him far less predictable and much harder to exploit.
- **Run 6 Impact (Tuned: 0.03)**:
  - **Tournament Wins**: Rose further to **12 wins (24%)** (from 10 in Run 5 and 7 in Run 4).
  - **Active Win Rate**: Jumped to **47.80%** (359 wins out of 751 active rounds).
  - **Analysis**: Similar to Grandma, Mr. Case's pot odds calculation benefited immensely from a small flat jitter (0.03). It introduced subtle, unpredictable variations to his otherwise rigid mathematical constraints, effectively acting as natural, well-timed bluffs that kept opponents off-guard.

---

### 3. Detailed Round-Level Metrics (Run 4 vs. Run 5 vs. Run 6)

Below is the comparative raw performance data from the game engine logs at the end of Run 4 (0.0 error), Run 5 (with error), and Run 6 (with tuned low error):

| Metric | Grandma (R4 / R5 / R6) | Kyle (R4 / R5 / R6) | Mr. Case (R4 / R5 / R6) | Michelle (R4 / R5 / R6) |
| :--- | :---: | :---: | :---: | :---: |
| **Total Games** | 1000 / 1025 / 1044 | 1000 / 1025 / 1044 | 1000 / 1025 / 1044 | 1000 / 1025 / 1044 |
| **Active Games** | 974 / 1013 / 1037 | 726 / 719 / 728 | 617 / 735 / 751 | 757 / 693 / 654 |
| **Round Wins** | 264 / 294 / 344 | 404 / 391 / 373 | 230 / 334 / 359 | 397 / 306 / 253 |
| **Active Win Rate** | 27.10% / 29.02% / 33.17% | 55.65% / 54.38% / 51.24% | 37.28% / 45.44% / 47.80% | 52.44% / 44.16% / 38.69% |
| **Total Folds** | 515 / 550 / 520 | 86 / 124 / 96 | 161 / 183 / 176 | 170 / 184 / 173 |
| **Folds Normalized** | 52.87% / 54.29% / 50.14% | 11.85% / 17.25% / 13.19% | 26.09% / 24.90% / 23.44% | 22.46% / 26.55% / 26.45% |
| *-- Preflop Folds* | 345 / 365 / 342 | 2 / 44 / **5** | 107 / 114 / 110 | 110 / 120 / 116 |
| *-- Flop Folds* | 71 / 83 / 82 | 15 / 27 / 13 | 15 / 21 / 13 | 18 / 17 / 17 |
| *-- Turn Folds* | 50 / 56 / 49 | 18 / 26 / 29 | 10 / 17 / 14 | 11 / 17 / 9 |
| *-- River Folds* | 49 / 46 / 47 | 51 / 27 / 49 | 29 / 31 / 39 | 31 / 30 / 31 |
| **Avg Fold Phase** | 0.617 / 0.605 / 0.617 | **2.372 / 1.290 / 2.271** | 0.758 / 0.809 / 0.898 | 0.782 / 0.766 / 0.740 |
| **Avg Win Prob @ Fold** | 29.51% / 27.06% / 27.89% | 5.51% / 4.30% / 5.62% | 16.72% / 13.40% / 15.33% | 16.81% / 16.13% / 17.23% |
| **Avg Pot Odds @ Fold** | 22.07% / 21.70% / 21.42% | 7.37% / 12.75% / 9.00% | 28.77% / 26.61% / 27.37% | 28.64% / 28.34% / 29.28% |

---

### 4. Wins by Showdown Hand Rank (Run 4 vs. Run 5 vs. Run 6)

This table tracks showdown victories by hand rank (excluding eligibility wins) for Run 4 (0.0 error), Run 5 (with error), and Run 6 (with tuned low error):

| Hand Rank | Grandma (R4/R5/R6) | Kyle (R4/R5/R6) | Mr. Case (R4/R5/R6) | Michelle (R4/R5/R6) |
| :--- | :---: | :---: | :---: | :---: |
| **High Card** | 5 / 14 / 16 | 9 / 7 / 8 | 7 / 9 / 7 | 9 / 8 / 6 |
| **Pair** | 85 / 75 / 121 | 66 / 74 / 78 | 61 / 79 / 77 | 82 / 74 / 63 |
| **Two Pair** | 78 / 89 / 92 | 93 / 63 / 61 | 52 / 72 / 78 | 71 / 62 / 62 |
| **Three of a Kind** | 26 / 27 / 22 | 23 / 26 / 20 | 17 / 23 / 17 | 15 / 18 / 20 |
| **Straight / Wheel**| 30 / 23 / 21 | 39 / 23 / 32 | 18 / 27 / 25 | 35 / 24 / 22 |
| **Flush** | 13 / 16 / 16 | 16 / 14 / 15 | 9 / 12 / 11 | 20 / 14 / 12 |
| **Full House** | 6 / 17 / 24 | 12 / 20 / 18 | 14 / 15 / 14 | 15 / 12 / 7 |
| **Four of a Kind** | 1 / 1 / 0 | 3 / 2 / 3 | 0 / 1 / 0 | 0 / 0 / 0 |
| **Total Showdown Wins**| **244 / 262 / 312** | **261 / 229 / 235** | **178 / 238 / 229** | **247 / 212 / 192** |

---

### 5. Interesting Records & Observations

#### 💰 Record-Breaking Pots
* **Run 6 Max Pot**: **39,456 chips**, won by **Grandma** with **Two Pair** (Community: `7s Kd 4h 7d Qs`).
* **Run 5 Max Pot**: **38,400 chips**, won by **Kyle** with **Two Pair** (Community: `5d Ah 8h Ks 8c`). Kyle held `As 8d` for Aces and Eights.
* *Comparison (Run 4)*: **38,400 chips**, won by **Grandma** with a **Pair** of Aces (Community: `6d 5d 4h Js Ad`).

#### 🃏 Toughest Fold
* **Run 6 Max Win Prob Folded**: **0.497903** by **Grandma** preflop holding `2h Qc`.
* **Run 5 Max Win Prob Folded**: **0.499895** by **Grandma** preflop holding `Ts 2s` (empty community). This shows that even with ±0.1 error, her core logic remains highly tight preflop, folding coin flips.
* *Comparison (Run 4)*: **0.50** by **Grandma** preflop holding `4s Qd`.

---

### 6. Conclusions & Tactical Takeaways

1. **The Asymmetric Impact of Decision Noise**:
   - Introducing decision noise (error jitter) is **highly beneficial for passive/overly-predictable players** (Grandma and Mr. Case) because it forces them to stay in more pots and play more aggressively, adding an accidental bluff element.
   - Introducing decision noise is **extremely detrimental for optimal/balanced players** (Michelle) and **highly volatile players** (Kyle) because it disrupts fine-tuned logic or drives them to make excessively risky/suboptimal decisions.
2. **Selective Folding vs. Random Folding**:
   - Kyle's spike to 44 preflop folds shows that noise can force a loose player to fold, but since it is random and not based on card strength, it does not improve his baseline profitability.
3. **Robustness of Conservative Strategies**:
   - Grandma's survival-first approach is incredibly robust. Even with ±0.1 error, she survived 100% of tournaments without ever being eliminated first. Noise actually helped her win more tournaments because she had more chips in late stages.
4. **Tuned Low Flat Jitter Strategy Success (Run 6)**:
   - Lowering Grandma's and Mr. Case's error rate to 0.03, Kyle's to 0.05, and Michelle's to 0.01 successfully preserved their core identities and strategic profiles while injecting a very subtle, natural level of unpredictability.
   - Grandma was undefeated (0 first-outs) but grew much more active and won a dominant 17 tournaments.
   - Mr. Case played aggressively and successfully converted his mathematical model into 12 tournament victories.
   - Kyle's pre-flop folding issue was completely resolved, dropping from 44 back to just 5.
   - This proved that extremely low, tuned flat jitter scales are highly effective in poker simulations to balance realistic decision noise and strategy correctness.
