#!/bin/sh
# Wrapper to enforce player connection limit

# Default limit of active players is 100
MAX_PLAYERS=${MAX_PLAYERS:-100}

# Count active game processes
# Portable across macOS and Linux by using pgrep and counting lines with wc
ACTIVE_PLAYERS=$(pgrep -x pokerd | wc -l | tr -d ' ')

if [ "$ACTIVE_PLAYERS" -ge "$MAX_PLAYERS" ]; then
    echo "--------------------------------------------------------"
    echo "Sorry, my puny personal server is at its limit for"
    echo "the pokerd game. Please consider installing the game"
    echo "locally (see https://github.com/filiph/pokerd)."
    echo "Otherwise, please try again in a few minutes."
    echo "                                          - Filip Hracek"
    echo "--------------------------------------------------------"
    exit 0
fi

exec /usr/local/bin/pokerd
