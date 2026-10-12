#!/bin/zsh
set -eu

script_dir="${0:A:h}"
mkdir -p "$HOME/.local/bin"
install -m 755 "$script_dir/airdrop-now" "$HOME/.local/bin/airdrop-now"
"$HOME/.local/bin/airdrop-now" setup
print -- "Installed: $HOME/.local/bin/airdrop-now"
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  print -- "Add $HOME/.local/bin to PATH, or call the installed command by its full path."
fi
