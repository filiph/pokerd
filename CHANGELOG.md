## 1.0.16

- Introduce decision error/jitter rates for NPC players to simulate realistic decision noise and strategic unpredictability.
- Fine-tune NPC strategic thresholds and logic (such as Grandma's conservative boundaries, Kyle's overconfidence, and Michelle/Mr. Case's preflop adjusted pot odds).
- Add new `analyze_log.dart` tool to parse self-play logs and generate detailed tournament reports and player profiles.
- Add comprehensive computer player behavior unit tests.
- Harden the SSH service deployment with resource constraints, container log rotation, restricted access, and tunnel prevention.

## 1.0.15

- Add SSH service support allowing users to play the poker game over SSH.
- Gracefully limit maximum concurrent players using the `MAX_PLAYERS` environment variable.
- Configure `play` user login shell to `/bin/sh` to avoid ForceCommand `-c` option issues.
- Automatically reboot the game on deploy and fix environment variable propagation.
- Add redirect server supporting redirection to poker.filiph.net.
- Rename NPC opponent "Mr Suitcase" to "Mr Case".
- Add release process documentation.

## 1.0.14

- Balance NPC opponents and add more stats.

## 1.0.13

- Add Linux ARM64 and Windows ARM64 build targets, remove macOS Intel.

## 1.0.12

- Fix Homebrew tag resolution for source tarball.

## 1.0.11

- Switch GitHub Releases to true single-file native executables.

## 1.0.10

- Update description and README badges.

## 1.0.9

- Improve Homebrew installation instructions in README.

## 1.0.8

- Update Homebrew installation instructions to mention dart-lang/dart trust requirement.

## 1.0.7

- Update Homebrew installation instructions in README.

## 1.0.6

- Update README and documentation.

## 1.0.5

- Retry automated pub.dev release.

## 1.0.4

- Test fully automated release pipeline (GitHub, pub.dev, Homebrew).

## 1.0.3

- Fix Homebrew formula push authentication.

## 1.0.2

- Restrict build targets to macOS, Linux, and Windows.

## 1.0.1

- Fix release pipeline.

## 1.0.0

- Initial version.
