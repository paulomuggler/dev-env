# GitHub CLI Configuration

Configuration for [gh](https://cli.github.com/) - GitHub's official command line tool.

## What's Included

- `gh.sh`: Shell completion and aliases

## First-time Setup

After installation, authenticate with GitHub:

```bash
gh auth login
```

Set your preferred editor:

```bash
gh config set editor nvim
```

## Common Commands

### Repositories
```bash
gh repo clone owner/repo    # Clone a repository
gh repo create              # Create a new repository
gh repo view                # View repository details
gh browse                   # Open repo in browser
```

### Pull Requests
```bash
gh pr create                # Create a PR
gh pr list                  # List PRs
gh pr view [number]         # View PR details
gh pr checkout [number]     # Checkout PR locally
gh pr merge [number]        # Merge a PR
```

### Issues
```bash
gh issue create             # Create an issue
gh issue list               # List issues
gh issue view [number]      # View issue details
gh issue close [number]     # Close an issue
```

### Workflows (GitHub Actions)
```bash
gh run list                 # List workflow runs
gh run view [id]            # View run details
gh run watch               # Watch a run in real-time
```

## Aliases

Configured in `gh.sh`:
- `ghpr` - List pull requests
- `ghprc` - Create pull request
- `ghprv` - View pull request
- `ghrc` - Clone repository
- `ghrv` - View repository
