# pr-reminder

Scans your Slack PR channel for unreviewed pull requests, fetches each diff, and sends you a private briefing via DM. Works with Claude Code or GitHub Copilot CLI.

```
🔍  pr-reminder
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

1. Prompts you to pick Claude Code or GitHub Copilot CLI
2. Fetches recent messages from your Slack PR channel via MCP
3. Finds any GitHub PR links and checks each one for missing approvals
4. Pulls the diff for each unreviewed PR
5. Produces a summary, risk flags, and suggested inline comments
6. Sends the briefing to your Slack DMs, not to the PR channel

---

## Requirements

| Tool | Version | Install |
|------|---------|---------|
| [gum](https://github.com/charmbracelet/gum) | latest | `brew install gum` |
| [Node.js](https://nodejs.org) | 18+ | `brew install node` |
| [Claude Code](https://www.anthropic.com/claude-code) | latest | `npm install -g @anthropic-ai/claude-code` |
| [GitHub Copilot CLI](https://github.com/github/copilot-cli) | latest | `npm install -g @github/copilot` |

You only need one of Claude Code or Copilot CLI. The script will use whichever is installed, or ask you to pick if both are present.

**Claude Code** requires a Claude Pro or Max subscription, or an Anthropic API key.  
**Copilot CLI** requires a GitHub Copilot subscription (Free, Pro, Business, or Enterprise).

---

## MCP setup

Both tools use the same Slack and GitHub MCP servers. The only difference is where the config lives.

### Claude Code: `~/.claude/settings.json`

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

### Copilot CLI: `~/.copilot/mcp-config.json`

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

The server config is the same for both. Just put it in the right file.

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
4. Invite the bot to your PR channel: `/invite @pr-reminder`

**Slack team ID**
- Open Slack in a browser. The team ID is the segment starting with `T` in the URL: `app.slack.com/client/T0123ABCD/...`
- Or run: `curl -s -H "Authorization: Bearer xoxb-your-token" https://slack.com/api/auth.test | jq '.team_id'`

**GitHub personal access token**
1. Go to [github.com/settings/tokens](https://github.com/settings/tokens)
2. Generate a new token (classic) with `repo` scope
3. Copy the token (starts with `ghp_`)

> **Note:** Copilot CLI does not support classic PATs for authenticating the CLI itself, but the GitHub MCP server uses your token directly and works fine with them.

---

## Installation

```bash
# Clone the repo
git clone https://github.com/your-username/pr-reminder
cd pr-reminder

# Make the script executable
chmod +x pr-reminder.sh

# Optionally move it onto your PATH
mv pr-reminder.sh ~/.local/bin/pr-reminder
```

---

## Usage

```bash
# Interactive mode
pr-reminder

# Skip the channel and email prompts by passing them as arguments
pr-reminder "#eng-prs"
pr-reminder "#eng-prs" "you@company.com"
```

The email helps the AI find your Slack user ID to send the DM. You can leave it out if your workspace resolves your identity from context.

---

## Scheduling

`gum` needs an interactive terminal, so skip the script and call the AI directly for cron jobs:

```bash
# Claude Code, every weekday at 9am and 2pm
0 9,14 * * 1-5 claude --permission-mode acceptEdits \
  -p "Using the Slack and GitHub MCP tools, check #pull-requests for unreviewed PRs and DM me a briefing. My email is you@company.com."

# Copilot CLI
0 9,14 * * 1-5 copilot --allow-tool slack --allow-tool github --deny-tool shell \
  -p "Using the Slack and GitHub MCP tools, check #pull-requests for unreviewed PRs and DM me a briefing. My email is you@company.com."
```

---

## Customisation

The prompt is defined inline in `pr-reminder.sh` as the `PROMPT` variable. Edit it to:

- Change the briefing format
- Adjust what counts as a risk area
- Add your own review guidelines or coding standards
- Target a different time window (default is last 24 hours)

---

## License

MIT
