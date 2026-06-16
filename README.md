A command line Texas Hold'em implementation.

This project is meant as a Texas Hold'em "trainer" for beginner players.
It's a sandbox for trying out strategies and building an intuition
for the probabilities involved in poker.

[![No Maintenance Intended](http://unmaintained.tech/badge.svg)](http://unmaintained.tech/) (This is a personal project.)

https://github.com/user-attachments/assets/4ce314fa-730d-4a0c-bd38-2e27b2c55b45


## Install

#### Homebrew (macOS / Linux)

Homebrew may ask you to trust the tap first.
If it does, simply run
<code>brew trust <a href="https://github.com/filiph/homebrew-tap">filiph/tap</a></code>
as instructed by the terminal.
Because `pokerd` compiles from source,
you may also be asked to trust the official Dart programming language tap:
<code>brew trust <a href="https://github.com/dart-lang/homebrew-dart">dart-lang/dart</a></code>.

```bash
brew trust dart-lang/dart
brew trust filiph/tap
```

After that, or if you've already trusted the taps above, just run:

```bash
brew tap filiph/tap
brew install pokerd
```


#### Pub.dev (macOS / Linux / Windows)

```bash
dart pub global activate pokerd
```

#### Direct Download (Windows / macOS / Linux)

Download the standalone executable for your operating system
from the [Releases](https://github.com/filiph/pokerd/releases) page.
Extract the archive and run the binary.


## Run

```bash
pokerd
```
