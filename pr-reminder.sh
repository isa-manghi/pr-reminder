#!/usr/bin/env bash
# pr-reminder.sh
# Interactive PR review briefing using gum + Claude Code or Copilot CLI + MCP
#
# Dependencies:
#   - gum     (brew install gum)
#   - claude  (npm install -g @anthropic-ai/claude-code)     — for Claude Code
#   - copilot (npm install -g @github/copilot)               — for Copilot CLI
#
# MCP config:
#   Claude Code : ~/.claude/settings.json
#   Copilot CLI : ~/.copilot/mcp-config.json
#   Both need Slack + GitHub MCP servers configured.

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

HAS_CLAUDE=false
HAS_COPILOT=false
command -v claude &>/dev/null && HAS_CLAUDE=true
command -v copilot &>/dev/null && HAS_COPILOT=true

if ! $HAS_CLAUDE && ! $HAS_COPILOT; then
  gum style \
    --foreground "$RED" \
    --border rounded \
    --border-foreground "$RED" \
    --padding "0 2" \
    "Neither Claude Code nor Copilot CLI is installed." \
    "  Claude Code : npm install -g @anthropic-ai/claude-code" \
    "  Copilot CLI : npm install -g @github/copilot"
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
  "🔍  pr-reminder · PR Review Briefing"

# ── Choose AI tool ────────────────────────────────────────────────────────────
if $HAS_CLAUDE && $HAS_COPILOT; then
  AI_TOOL=$(gum choose \
    --header "Which AI would you like to use?" \
    --header.foreground "$PURPLE" \
    --selected.foreground "$PINK" \
    "Claude Code" \
    "GitHub Copilot CLI")
elif $HAS_CLAUDE; then
  AI_TOOL="Claude Code"
else
  AI_TOOL="GitHub Copilot CLI"
fi

gum style --foreground "$GRAY" "  Using    : $AI_TOOL"

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
gum style --foreground "$GRAY" "  Channel  : $CHANNEL"
[[ -n "$EMAIL" ]] && gum style --foreground "$GRAY" "  Email    : $EMAIL"
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
   - Risk areas worth scrutinising (auth, error handling, security, performance, DB migrations, etc.) — keep each flag to a short phrase
   - 2-3 suggested inline review comments with filename and approximate line reference
   - An overall signal: one of exactly: ✅ Looks good | 👀 Worth a closer look | 🚨 Needs discussion

4. Use Slack MCP to send me a single DM (not to the PR channel).${EMAIL_HINT}

Send the message using blocks for rich formatting. Structure it as follows:

First, a header section:
- A header block: '🔍  PR Review Briefing'
- A context block showing the date and channel, e.g. 'Today · ${CHANNEL} · N of N unreviewed'
- A divider

Then for each unreviewed PR:
- A section block with the PR title as bold mrkdwn: '*#<number> — <title>*'
- A context block: 'by @<author> · opened <time ago>'
- A section block for the 2-3 sentence summary
- A section block labelled '*Flags*' listing each flag separated by ' · ', or 'None' if clean
- A section block labelled '*Suggested comments*' with each comment on its own line as: \`<file> ~L<line>\`  <comment>
- A section block with '*<signal>*' on one side and a link on the other: 'View on GitHub ↗'
- A divider between each PR

End with a context block: 'Checked ${CHANNEL} · <N> unreviewed · pr-reminder'

If there are no unreviewed PRs, send a simple DM: '✅ All clear — no unreviewed PRs right now.'

Be concise. Signal over noise. Post nothing to the PR channel itself."

# ── Run with the chosen tool ──────────────────────────────────────────────────
#
# Security notes:
#
# Claude Code  — uses --permission-mode acceptEdits (auto mode) instead of
#                --dangerously-skip-permissions. The safety classifier stays
#                active and blocks genuinely risky actions. Only MCP tool calls
#                and read operations are expected; no file writes or shell
#                commands should be needed for this task.
#
# Copilot CLI  — uses scoped --allow-tool flags to permit only the two MCP
#                servers this task needs (slack and github). All shell
#                execution, file writes, and other tools remain blocked.
#                --deny-tool shell provides an explicit hard block on shell
#                commands as a belt-and-braces measure.
#
if [[ "$AI_TOOL" == "Claude Code" ]]; then
  RUN_CMD=(
    claude
    --permission-mode acceptEdits
    -p "$PROMPT"
  )
  SPINNER_TITLE="Claude is checking PRs in ${CHANNEL}..."
else
  RUN_CMD=(
    copilot
    --allow-tool "slack"
    --allow-tool "github"
    --deny-tool "shell"
    -p "$PROMPT"
  )
  SPINNER_TITLE="Copilot is checking PRs in ${CHANNEL}..."
fi

gum spin \
  --spinner dot \
  --spinner.foreground "$PINK" \
  --title "$SPINNER_TITLE" \
  --title.foreground "$PURPLE" \
  -- "${RUN_CMD[@]}"

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
