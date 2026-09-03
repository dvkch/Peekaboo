#!/bin/bash
set -euo pipefail

# Usage: ./build.sh -- sync
#        ./build.sh -- cleanup
#
# Anything after a literal "--" is forwarded to the built binary.
# Anything before it is reserved for future build-script-only flags.

ARGS=()
FOUND_SEPARATOR=false
for arg in "$@"; do
  if $FOUND_SEPARATOR; then
    ARGS+=("$arg")
  elif [ "$arg" = "--" ]; then
    FOUND_SEPARATOR=true
  fi
done

# Pull the executable's name straight from Package.swift rather than
# hardcoding it, so this doesn't silently go stale after a rename.
EXECUTABLE=peekaboo

echo "Building $EXECUTABLE (debug)..."
swift build

BIN_PATH="$(swift build --show-bin-path)/$EXECUTABLE"

if [ ! -x "$BIN_PATH" ]; then
  echo "Built binary not found at: $BIN_PATH" >&2
  exit 1
fi

echo "Running: $BIN_PATH ${ARGS[*]}"
"$BIN_PATH" "${ARGS[@]}"
