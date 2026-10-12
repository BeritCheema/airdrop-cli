# Agent workflow

When asked to AirDrop a local file, run `airdrop-now doctor`, then `airdrop-now devices` if no saved target is known. Use an exact device label from discovery. Save the user's phone once with `airdrop-now use "<exact label>"`, then send files with `airdrop-now <path>`. An explicit `--to` overrides the saved device for one send. Treat a nonzero exit as failure and report the actual reason. Accessibility approval is a one-time macOS action that only the user can grant.

Do not guess among multiple plausible devices or claim a transfer succeeded before the command exits successfully. `auto-airdrop-cli` provides the native share session and checks completion.
