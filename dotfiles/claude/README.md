# Claude Code Configuration

Stow package for Claude Code custom configurations, hooks, skills, and slash commands.

## Contents

- `dot-claude/` - User-level Claude Code configuration
  - `CLAUDE.md` - User-level system prompt (loaded for all projects)
  - `settings.json` - Claude settings including hooks configuration
  - `hooks/` - Hook scripts for automation
  - `skills/` - Custom skills (todo)
- `commands/` - Custom slash commands

**Note:** The lint-fix, code-review, architecture-review skills and coding-standards have been
migrated to the [steward](https://github.com/paulomuggler/steward) plugin at `~/Projects/steward/`.
The original sources are preserved in git history. The steward plugin is installed via symlink
at `~/.claude/plugins/steward/`.

## Managed Files

When stowed, this package creates symlinks for:

| Target | Source |
|--------|--------|
| `~/.claude/CLAUDE.md` | User-level instructions |
| `~/.claude/settings.json` | Hooks and settings config |
| `~/.claude/hooks/` | Hook scripts directory |
| `~/.claude/skills/todo/` | Task management skill |
| `~/commands/` | Custom slash commands |

**Not managed** (kept as-is):
- `~/.claude/skills/omarchy/` - System-provided skill (symlink to omarchy)
- Session data, caches, telemetry, projects, etc.

## Hooks

### SessionStart (compact)
- `todo-resume.sh` - Re-injects /todo work protocol after context compaction

### Stop
- `todo-work-loop-stop.sh` - Prevents stopping when work loop phases are incomplete

### PermissionRequest (ExitPlanMode)
- `auto-approve-plan.sh` - Auto-approves plan if it matches current TODO task

## Skills

### `/todo` - Task Management
Full task tracking system with file-per-task workflow:
- Creates tasks in `.agents/TODO/`
- Tracks phases: plan → execute → verify → complete
- Maintains work state for context continuity

### Steward Plugin (external)

Lint, code review, architecture review, and coding standards are now managed by the
**steward** plugin (`~/.claude/plugins/steward/`). Skills: `/steward:lint`,
`/steward:review`, `/steward:arch`, `/steward:standards`.

## Custom Slash Commands

### `/implement-prompts`

Scans files for `# AI: <prompt>` markers and implements the requested changes.

**Usage:**
```bash
/implement-prompts path/to/file.sh
```

## Installation

Handled automatically by `install-scripts/install-claude-code.sh`:

```bash
./install-scripts/install-claude-code.sh
```

Or manually:

```bash
# Ensure ~/.claude exists
mkdir -p ~/.claude/skills

# Remove existing files (stow won't overwrite)
rm -f ~/.claude/CLAUDE.md ~/.claude/settings.json
rm -rf ~/.claude/hooks
rm -rf ~/.claude/skills/todo ~/.claude/skills/review ~/.claude/skills/architecture-review

# Stow
cd dotfiles && stow --dotfiles -t ~ claude
```

## Development

When adding new skills:
1. Create skill directory in `dot-claude/skills/`
2. Add `SKILL.md` with frontmatter (name, description, user-invocable, etc.)
3. Optionally add `README.md` and `guides/` subdirectory
4. Test locally before committing

When adding hooks:
1. Create executable script in `dot-claude/hooks/`
2. Register hook in `dot-claude/settings.json`
3. Follow hook output JSON format per Claude Code docs
