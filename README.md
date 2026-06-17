A command line Texas Hold'em implementation.

This project is meant as a Texas Hold'em "trainer" for beginner players.
It's a sandbox for trying out strategies and building an intuition
for the probabilities involved in poker.

This is a personal project.  
[![No Maintenance Intended](https://unmaintained.tech/badge.svg)](https://unmaintained.tech/)

<img width="800" height="525" alt="pokerd in motion, a screencast gif" src="https://github.com/user-attachments/assets/3789fa19-fef2-4996-8ee5-e6cdb23485a9" />


## Play Instantly via SSH (no install)

You can play the game instantly in your terminal by connecting to the live server:

```bash
ssh play@poker.filiph.net
```

### Note on First Connection:

When you connect for the first time,
`ssh` will prompt you to verify the server's public key fingerprint:

```text
The authenticity of host 'poker.filiph.net (....)' can't be established.
...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

To proceed, you *must type the full word `yes`*.
Simply hitting *Enter* without typing `yes` may default to `no` on some systems,
which leads to a `Host key verification failed` error.)*


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
