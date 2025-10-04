# Claude Code Configuration

Stow package for Claude Code custom configurations, slash commands, and prompts.

## Contents

- `commands/` - Custom slash commands
- `prompts/` - Custom system prompts (future)

## Custom Slash Commands

### `/implement-prompts`

Scans files for `# AI: <prompt>` markers and implements the requested changes.

**Usage:**
```bash
/implement-prompts path/to/file.sh
```

**Marker Syntax:**
```bash
# AI: Add error handling here
# AI: Refactor this function to use array iteration
```

The command will:
1. Extract all `# AI:` markers from the file
2. Provide full file context
3. Implement each requested change
4. Preserve file structure and style

## Installation

From the dev-env root:

```bash
stow -d dotfiles -t ~/.claude claude
```

**Note:** We stow directly into `~/.claude` (not `~`) because Claude Code manages other files in that directory that we don't want to control.

## Future Migration Plan

**Current Status:** Local stow package within dev-env repository

**Planned Migration:**
When this configuration grows and matures, we'll extract it to a dedicated repository:

- **Repo name:** `ai-assistant-configs` (or similar)
- **Structure:** Branch per assistant (claude-code, cursor, gemini, codex, etc.)
- **Integration:** Add as git submodule to dev-env
- **Benefit:** Cleaner separation, parallel installs without path conflicts

**Why wait?**
- Faster iteration during initial development
- Simpler testing without submodule overhead
- Unclear scope until we have more slash commands/prompts
- Easy migration path when ready

**Migration will be straightforward:**
1. Create new repo with branch-per-assistant structure
2. Move `dotfiles/claude/` → new repo `claude-code` branch
3. Add as submodule: `git submodule add -b claude-code <repo> dotfiles/claude`
4. Stow continues to work identically

## Development

When adding new slash commands:
1. Create markdown file in `commands/` (e.g., `my-command.md`)
2. Add frontmatter with description, argument hints, allowed tools
3. Write the command prompt template using `$ARGUMENTS` or `$1`, `$2`, etc.
4. Test locally before committing
5. Document in this README

## Notes

- Uses `# AI:` marker syntax for inline prompts
- Slash commands are markdown files with frontmatter, not shell scripts
- Commands have access to full Claude Code context by default
