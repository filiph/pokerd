#!/bin/sh
set -e

# Increase file descriptor limits for SSH connections to handle usage spikes
ulimit -n 65535 || true

# Ensure host keys directory exists
mkdir -p /etc/ssh/host_keys

# Generate host keys if they don't exist
if [ ! -f /etc/ssh/host_keys/ssh_host_rsa_key ]; then
    echo "Generating SSH RSA host key..."
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/host_keys/ssh_host_rsa_key
fi

if [ ! -f /etc/ssh/host_keys/ssh_host_ecdsa_key ]; then
    echo "Generating SSH ECDSA host key..."
    ssh-keygen -q -N "" -t ecdsa -f /etc/ssh/host_keys/ssh_host_ecdsa_key
fi

if [ ! -f /etc/ssh/host_keys/ssh_host_ed25519_key ]; then
    echo "Generating SSH Ed25519 host key..."
    ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/host_keys/ssh_host_ed25519_key
fi

# Fix permissions for host keys
chmod 600 /etc/ssh/host_keys/ssh_host_*_key
chmod 644 /etc/ssh/host_keys/ssh_host_*.pub

# Ensure run directory for sshd exists
mkdir -p /var/run/sshd

# Start SSH daemon in the foreground
echo "Starting OpenSSH server..."
exec /usr/sbin/sshd -D -e
