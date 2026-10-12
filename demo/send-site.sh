#!/bin/sh
set -eu
if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  printf 'Usage: %s "Exact AirDrop device name"\n' "$0" >&2
  exit 2
fi
exec "$HOME/.local/bin/airdrop-cli" --to "$1" https://beritcheema.github.io/airdrop-cli/
