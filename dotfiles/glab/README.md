# GitLab CLI Configuration

Configuration for [glab](https://gitlab.com/gitlab-org/cli) - GitLab's official command line tool.

## What's Included

- `glab.sh`: Shell completion and aliases

## First-time Setup

After installation, authenticate with GitLab:

```bash
glab auth login
```

Set your preferred editor:

```bash
glab config set editor nvim
```

## Common Commands

### Repositories
```bash
glab repo clone group/project   # Clone a repository
glab repo create                # Create a new repository
glab repo view                  # View repository details
glab repo view -w               # Open repo in browser
```

### Merge Requests
```bash
glab mr create                  # Create a MR
glab mr list                    # List MRs
glab mr view [id]               # View MR details
glab mr checkout [id]           # Checkout MR locally
glab mr merge [id]              # Merge a MR
glab mr approve [id]            # Approve a MR
```

### Issues
```bash
glab issue create               # Create an issue
glab issue list                 # List issues
glab issue view [id]            # View issue details
glab issue close [id]           # Close an issue
```

### CI/CD Pipelines
```bash
glab ci status                  # Show pipeline status
glab ci view                    # View pipeline details
glab ci list                    # List pipelines
glab ci trace                   # View job logs
```

## Aliases

Configured in `glab.sh`:
- `glmr` - List merge requests
- `glmrc` - Create merge request
- `glmrv` - View merge request
- `glrc` - Clone repository
- `glrv` - View repository
