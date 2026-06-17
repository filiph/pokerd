# ==========================================
# Stage 1: Build the native Dart executable
# ==========================================
FROM dart:stable AS builder

WORKDIR /app

# Copy dependency files and fetch packages
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Copy the remaining source files
COPY . .

# Compile the poker game binary to a native executable
RUN dart compile exe bin/pokerd.dart -o bin/pokerd

# ==========================================
# Stage 2: Run the game via OpenSSH
# ==========================================
FROM debian:stable-slim

# Install OpenSSH server, procps (for pgrep), and cleanup packages to keep image small
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy the compiled native game executable from the builder stage
COPY --from=builder /app/bin/pokerd /usr/local/bin/pokerd
RUN chmod +x /usr/local/bin/pokerd

# Copy the SSH daemon config, wrapper, and entrypoint script
COPY ssh_service/sshd_config /etc/ssh/sshd_config
COPY ssh_service/max_players_wrapper.sh /usr/local/bin/max_players_wrapper.sh
RUN chmod +x /usr/local/bin/max_players_wrapper.sh
COPY ssh_service/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Create the 'play' user with its shell set to /bin/sh (sshd will use it to invoke ForceCommand)
RUN useradd -m -d /home/play -s /bin/sh play && \
    passwd -d play

# Ensure host keys folder and sshd run directory exist
RUN mkdir -p /etc/ssh/host_keys /var/run/sshd

# Default environment to ensure 256-color support in terminal UI
ENV TERM=xterm-256color

EXPOSE 22

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
