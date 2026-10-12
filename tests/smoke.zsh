#!/bin/zsh
set -eu

repo="${0:A:h:h}"
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin"
cat > "$test_dir/bin/auto-airdrop" <<'EOF'
#!/bin/zsh
print -rl -- "$@" > "$AIRDROP_NOW_TEST_ARGS"
EOF
chmod +x "$test_dir/bin/auto-airdrop"
export PATH="$test_dir/bin:$PATH"
export AIRDROP_NOW_CONFIG_DIR="$test_dir/config"
export AIRDROP_NOW_TEST_ARGS="$test_dir/args"

"$repo/airdrop-now" use "My iPhone" >/dev/null
"$repo/airdrop-now" "$test_dir/a photo.jpg"
diff -u <(printf '%s\n' --yes --to 'My iPhone' "$test_dir/a photo.jpg") "$test_dir/args"

"$repo/airdrop-now" --to "Other iPhone" "$test_dir/second.jpg"
diff -u <(printf '%s\n' --yes --to 'Other iPhone' "$test_dir/second.jpg") "$test_dir/args"

"$repo/airdrop-now" devices
diff -u <(printf '%s\n' --list-devices) "$test_dir/args"

"$repo/airdrop-now" doctor
diff -u <(printf '%s\n' doctor) "$test_dir/args"

print -- "smoke tests passed"
