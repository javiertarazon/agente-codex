---
name: github
description: "Interact with GitHub using the `gh` CLI. Use `gh issue`, `gh pr`, `gh run`, and `gh api` for issues, PRs, CI runs, and advanced queries."
---

# GitHub Skill

Use the `gh` CLI to interact with GitHub. Always specify `--repo owner/repo` when not in a git directory, or use URLs directly.

## Pull Requests

Check CI status on a PR:

```bash
gh pr checks 55 --repo owner/repo
```

List recent workflow runs:

```bash
gh run list --repo owner/repo --limit 10
```

View a run and see which steps failed:

```bash
gh run view <run-id> --repo owner/repo
```

View logs for failed steps only:

```bash
gh run view <run-id> --repo owner/repo --log-failed
```

## Issues

```bash
# List open issues
gh issue list --repo owner/repo --state open --limit 20

# View issue details
gh issue view <number> --repo owner/repo

# Create issue
gh issue create --repo owner/repo --title "Bug: ..." --body "..."

# Close issue
gh issue close <number> --repo owner/repo
```

## API for Advanced Queries

The `gh api` command is useful for accessing data not available through other subcommands.

Get PR with specific fields:

```bash
gh api repos/owner/repo/pulls/55 --jq '.title, .state, .user.login'
```

Get authenticated user:

```bash
gh api user --jq .login
```

## JSON Output

Most commands support `--json` for structured output. You can use `--jq` to filter:

```bash
gh issue list --repo owner/repo --json number,title --jq '.[] | "\(.number): \(.title)"'
gh pr list --repo owner/repo --json number,title,state --jq '.[] | select(.state=="OPEN")'
```

## Auth

```bash
gh auth login          # autenticar
gh auth status         # verificar estado
gh auth token          # obtener token actual
```

## Repo para este workspace

- owner: `javiertarazon`
- repo: `agente-codex`
- URL: `https://github.com/javiertarazon/agente-codex`
