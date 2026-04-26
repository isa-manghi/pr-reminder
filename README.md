# prism

A shell script that scans your Slack PR channel for unreviewed pull requests, analyses each diff, and DMs you a private briefing — all from one command. Works with either **Claude Code** or **GitHub Copilot CLI**.

```
🔍  prism · PR Review Briefing
────────────────────────────────
? Which AI would you like to use?
  > Claude Code
    GitHub Copilot CLI

Slack channel › #pull-requests
Your email    › you@company.com

  Using    : Claude Code
  Channel  : #pull-requests
  Email    : you@company.com

Run briefing and DM results to your Slack? Yes

⠋ Claude is checking PRs in #pull-requests...

✅  Done! Check your Slack DMs for the briefing.
```

---

## What it does

1. Prompts you to choose between Claude Code or GitHub Copilot CLI
2. Fetches recent messages from your Slack PR channel via MCP
3. Extracts GitHub PR links and checks each one for missing approvals
4. Pulls the diff for each unreviewed PR via GitHub MCP
5. Produces a summary, risk flags, and suggested inline comments
6. DMs the full briefing directly to you in Slack — nothing posted to the PR channel

---

## Requirements

| Tool | Version | Install |
|------|---------|---------|
| [gum](https://github.com/charmbracelet/gum) | latest | `brew install gum` |
| [Node.js](https://nodejs.org) | 18+ | `brew install node` |
| [Claude Code](https://www.anthropic.com/claude-code) | latest | `npm install -g @anthropic-ai/claude-code` |
| [GitHub Copilot CLI](https://github.com/github/copilot-cli) | latest | `npm install -g @github/copilot` |

You only need one of Claude Code or Copilot CLI — the script will use whichever is installed, or ask you to choose if both are present.

**Claude Code** requires a Claude Pro or Max subscription, or an Anthropic API key.
**Copilot CLI** requires a GitHub Copilot subscription (Free, Pro, Business, or Enterprise).

---

## MCP setup

Both tools use the same Slack and GitHub MCP servers. The only difference is where the config lives.

### Claude Code — `~/.claude/settings.json`

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

### Copilot CLI — `~/.copilot/mcp-config.json`

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

The server config is identical — just drop it into the right file for your tool.

---

### Getting your tokens

**Slack bot token**
1. Go to [api.slack.com/apps](https://api.slack.com/apps) and create a new app
2. Under _OAuth & Permissions_, add these bot scopes:
   - `channels:history`
   - `im:write`
   - `users:read`
   - `users:read.email`
3. Install the app to your workspace and copy the `Bot User OAuth Token` (starts with `xoxb-`)
4. Invite the bot to your PR channel: `/invite @prism`

**Slack team ID**
- Open Slack in a browser — your Team ID is the segment starting with `T` in the URL: `app.slack.com/client/T0123ABCD/...`
- Or run: `curl -s -H "Authorization: Bearer xoxb-your-token" https://slack.com/api/auth.test | jq '.team_id'`

**GitHub personal access token**
1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Generate a new token (classic) with `repo` scope
3. Copy the token (starts with `ghp_`)

> **Note:** Copilot CLI does not support classic PATs (`ghp_`) for authenticating the CLI itself — but the GitHub MCP server uses your token directly and works fine with them.

---

## Installation

```bash
# Clone the repo
git clone https://github.com/your-username/prism
cd prism

# Make the script executable
chmod +x review-prs.sh

# Optionally move it onto your PATH
mv review-prs.sh ~/.local/bin/review-prs
```

---

## Usage

```bash
# Interactive — prompts for AI tool, channel, and email
review-prs

# Pass arguments directly to skip the channel and email prompts
review-prs "#eng-prs"
review-prs "#eng-prs" "you@company.com"
```

The email argument helps the AI look up your Slack user ID to send the DM. If your workspace can resolve your identity from context you can leave it out.

---

## Scheduling (optional)

`gum` requires an interactive terminal, so bypass the script entirely for cron jobs:

```bash
# Claude Code — every weekday at 9am and 2pm
0 9,14 * * 1-5 claude --dangerously-skip-permissions \
  -p "Using the Slack and GitHub MCP tools, check #pull-requests for unreviewed PRs and DM me a briefing. My email is you@company.com."

# Copilot CLI
0 9,14 * * 1-5 copilot --allow-all-tools \
  -p "Using the Slack and GitHub MCP tools, check #pull-requests for unreviewed PRs and DM me a briefing. My email is you@company.com."
```

---

## Customisation

The prompt is defined inline in `prism.sh` as the `PROMPT` variable. You can edit it directly to:

- Change the briefing format
- Adjust what counts as a risk area
- Add your own review guidelines or coding standards
- Target a different time window (default is last 24 hours)

---

## License

MIT
