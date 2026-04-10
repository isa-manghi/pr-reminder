# pr-review-briefing

A shell script that uses [Claude Code](https://www.anthropic.com/claude-code) and your Slack + GitHub MCP connections to scan a PR channel for unreviewed pull requests, analyse each diff, and DM you a private briefing, all from one command.

```
🔍  PR Review Briefing
─────────────────────
Slack channel › #pull-requests
Your email    › you@company.com

  Channel : #pull-requests
  Email   : you@company.com

Run briefing and DM results to your Slack? Yes

⠋ Checking PRs in #pull-requests...

✅  Done! Check your Slack DMs for the briefing.
```

---

## What it does

1. Fetches recent messages from your Slack PR channel via MCP
2. Extracts GitHub PR links and checks each one for missing approvals
3. Pulls the diff for each unreviewed PR via GitHub MCP
4. Asks Claude to produce a summary, flag risk areas, and suggest inline comments
5. DMs the full briefing directly to you in Slack — nothing posted to the PR channel

---

## Requirements

| Tool | Version | Install |
|------|---------|---------|
| [Claude Code](https://www.anthropic.com/claude-code) | latest | `npm install -g @anthropic-ai/claude-code` |
| [gum](https://github.com/charmbracelet/gum) | latest | `brew install gum` |
| [Node.js](https://nodejs.org) | 18+ | `brew install node` |

You'll also need a Claude Pro or Max subscription, or an Anthropic API key, to use Claude Code.

---

## MCP setup

This script relies on two MCP servers connected to Claude Code. Add them to `~/.claude/settings.json`:

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "xoxb-your-token-here",
        "SLACK_TEAM_ID": "T0123456789"
      }
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_your-token-here"
      }
    }
  }
}
```

### Getting your tokens

**Slack bot token**
1. Go to [api.slack.com/apps](https://api.slack.com/apps) and create a new app
2. Under _OAuth & Permissions_, add these bot scopes:
   - `channels:history`
   - `im:write`
   - `users:read`
   - `users:read.email`
3. Install the app to your workspace and copy the `Bot User OAuth Token`

**GitHub personal access token**
1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Generate a new token (classic) with `repo` scope
3. Copy the token

---

## Installation

```bash
# Clone the repo
git clone https://github.com/your-username/pr-review-briefing
cd pr-review-briefing

# Make the script executable
chmod +x review-prs.sh

# Optionally move it onto your PATH
mv review-prs.sh ~/.local/bin/review-prs
```

---

## Usage

```bash
# Interactive — prompts for channel and email
review-prs

# Pass arguments directly to skip prompts
review-prs "#eng-prs"
review-prs "#eng-prs" "you@company.com"
```

The email argument helps Claude look up your Slack user ID to send the DM. If your Slack workspace can resolve your identity from context alone you can leave it out.

---

## Scheduling (optional)

`gum` requires an interactive terminal, so for cron jobs call `claude` directly:

```bash
# Every weekday at 9am and 2pm
0 9,14 * * 1-5 claude --dangerously-skip-permissions \
  -p "Using the Slack and GitHub MCP tools, check #pull-requests for unreviewed PRs and DM me a briefing. My email is you@company.com."
```

---

## Customisation

The prompt is defined inline in `review-prs.sh` as the `PROMPT` variable. You can edit it directly to:

- Change the briefing format
- Adjust what counts as a risk area
- Add your own review guidelines or coding standards
- Target a different time window (default is last 24 hours)

---

## License

MIT
