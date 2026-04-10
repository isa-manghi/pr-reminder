#!/usr/bin/env bash
# review-prs.sh
# Interactive PR review briefing using gum + Claude Code + MCP (Slack & GitHub)
# No skill file required — prompt is inline.
#
# Dependencies:
#   - gum     (brew install gum)
#   - claude  (npm install -g @anthropic-ai/claude-code)
#
# MCP servers required in ~/.claude/settings.json:
#   - Slack MCP   (github.com/modelcontextprotocol/servers/slack)
#   - GitHub MCP  (github.com/modelcontextprotocol/servers/github)

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
PINK="#FF79C6"
PURPLE="#BD93F9"
GREEN="#50FA7B"
RED="#FF5555"
GRAY="#6272A4"

# ── Check dependencies ────────────────────────────────────────────────────────
if ! command -v gum &>/dev/null; then
  echo "gum is not installed. Run: brew install gum"
  exit 1
fi

if ! command -v claude &>/dev/null; then
  echo "Claude Code is not installed. Run: npm install -g @anthropic-ai/claude-code"
  exit 1
fi

# ── Header ────────────────────────────────────────────────────────────────────
gum style \
  --foreground "$PINK" \
  --border double \
  --border-foreground "$PURPLE" \
  --padding "1 4" \
  --margin "1 0" \
  --bold \
  "🔍  PR Review Briefing"

# ── Inputs ────────────────────────────────────────────────────────────────────
if [[ $# -ge 1 ]]; then
  CHANNEL="$1"
else
  CHANNEL=$(gum input \
    --placeholder "#pull-requests" \
    --prompt "Slack channel › " \
    --prompt.foreground "$PURPLE" \
    --width 40)
  CHANNEL="${CHANNEL:-#pull-requests}"
fi

if [[ $# -ge 2 ]]; then
  EMAIL="$2"
else
  EMAIL=$(gum input \
    --placeholder "you@company.com  (leave blank to skip)" \
    --prompt "Your email  › " \
    --prompt.foreground "$PURPLE" \
    --width 40)
fi

# ── Confirm ───────────────────────────────────────────────────────────────────
echo ""
gum style --foreground "$GRAY" "  Channel : $CHANNEL"
[[ -n "$EMAIL" ]] && gum style --foreground "$GRAY" "  Email   : $EMAIL"
echo ""

if ! gum confirm \
  --prompt.foreground "$PURPLE" \
  --selected.background "$PURPLE" \
  "Run briefing and DM results to your Slack?"; then
  gum style --foreground "$RED" "Cancelled."
  exit 0
fi

echo ""

# ── Build inline prompt ───────────────────────────────────────────────────────
EMAIL_HINT=""
[[ -n "$EMAIL" ]] && EMAIL_HINT=" My Slack email is ${EMAIL}."

PROMPT="Using the Slack and GitHub MCP tools:

1. Fetch the last 50 messages from the Slack channel ${CHANNEL} and extract any GitHub PR links.
2. For each PR, use GitHub MCP to check if it is still open and has no approving review. Skip PRs that are closed, already approved, or that I authored.
3. For each unreviewed PR, fetch the diff and analyse it. Produce:
   - A 2-3 sentence plain English summary of what the PR does
   - Risk areas worth scrutinising (auth, error handling, security, performance, DB migrations, etc.)
   - 2-3 suggested inline review comments with filename and approximate line reference
   - An overall signal: ✅ Looks good | 👀 Worth a closer look | 🚨 Needs discussion
4. Use Slack MCP to send me a single DM (not to the PR channel) with the full briefing.${EMAIL_HINT} Format each PR like:

---
*PR #<number> — \"<title>\"* by @<author>
📋 <summary>
⚠️ *Flags:* <risk areas, or 'None'>
💬 *Suggested comments:*
  • \`<file> ~L<line>\`: <comment>
🏷️ <signal>
🔗 <url>
---

If there are no unreviewed PRs, DM me: ✅ All clear — no unreviewed PRs right now.
Be concise. Post nothing to the PR channel itself."

# ── Run ───────────────────────────────────────────────────────────────────────
gum spin \
  --spinner dot \
  --spinner.foreground "$PINK" \
  --title "Checking PRs in ${CHANNEL}..." \
  --title.foreground "$PURPLE" \
  -- claude --dangerously-skip-permissions -p "$PROMPT"

EXIT_CODE=$?
echo ""

# ── Result ────────────────────────────────────────────────────────────────────
if [[ $EXIT_CODE -eq 0 ]]; then
  gum style \
    --foreground "$GREEN" \
    --border rounded \
    --border-foreground "$GREEN" \
    --padding "0 2" \
    "✅  Done! Check your Slack DMs for the briefing."
else
  gum style \
    --foreground "$RED" \
    --border rounded \
    --border-foreground "$RED" \
    --padding "0 2" \
    "❌  Something went wrong (exit $EXIT_CODE). Check your MCP config."
fi

echo ""