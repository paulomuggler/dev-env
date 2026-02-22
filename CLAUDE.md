# DevEnv - AI Assistant Guidelines

## Project Overview

This is a terminal-based development environment bootstrapping utility that creates a complete, reproducible development setup. The environment centers around a tmux-based workspace integrating LLM CLI tools with nvim for enhanced productivity.

## Critical Working Practices

### Directory Context Awareness
**ALWAYS verify your current working directory before running commands.**

Common mistakes to avoid:
- ❌ Running `./install-scripts/install-foo.sh` from `~` or unknown directory
- ❌ Using relative paths without knowing where you are
- ❌ Assuming you're in the project root

**Best practices:**
- ✅ Check `pwd` or verify context before running scripts
- ✅ Use `cd ~/Projects/dev-env &&` prefix for project-relative commands
- ✅ Use absolute paths when uncertain: `~/Projects/dev-env/install-scripts/install-foo.sh`
- ✅ When in doubt: navigate explicitly first, then execute

**Project root:** `/Users/paulomoreira/Projects/dev-env`

### Git Operations Without Switching Branches
**NEVER checkout a different branch when the working tree has stowed symlinks pointing into it.**

Switching branches can break symlinks (e.g., Hyprland config) when files exist on one branch but not another.

**Cherry-pick to another branch (using worktree):**
```bash
git worktree add /tmp/osx-wt osx
cd /tmp/osx-wt && git cherry-pick <commit>
cd ~/Projects/dev-env && git worktree remove /tmp/osx-wt
```

**Push a branch without checkout:**
```bash
git push origin osx
```

**Apply commits via patch (alternative):**
```bash
git format-patch -1 <commit> --stdout | git am --3way
```

### Project Familiarization Protocol
**ALWAYS familiarize yourself with project conventions before making changes.**

When starting work without full context (new conversation, after context compaction, or working on unfamiliar parts of the codebase):

**Required steps:**
1. **Scan project structure**: Use `Glob` to understand directory organization
   ```
   - install-scripts/*.sh       # Installation script patterns
   - dotfiles/*/                # Configuration package structure
   - libs/*.sh                  # Available utility functions
   ```

2. **Sample existing implementations**: Read 2-3 similar files to understand patterns
   - If adding a tool install script → read `install-scripts/install-bat.sh`, `install-scripts/install-fzf.sh`
   - If adding dotfiles → examine `dotfiles/bat/`, `dotfiles/fzf/` structures
   - If modifying utilities → check `libs/utils.sh` for existing functions

3. **Identify conventions**: Look for:
   - Naming patterns (e.g., `dot-` prefix for dotfiles)
   - Directory structure (e.g., tool configs in `dotfiles/[tool]/[tool].sh`, NOT in `dotfiles/shell/dot-shell.d/`)
   - Utility function usage (e.g., `link_shell_config`, `stow_package`, `report_changed`)
   - Error handling patterns
   - Documentation standards

4. **Work within established patterns**:
   - ✅ Follow the conventions you discovered
   - ✅ Use existing utility functions instead of reimplementing
   - ✅ Match coding style, structure, and organization
   - ❌ Don't invent new patterns when established ones exist
   - ❌ Don't make assumptions about file locations or naming

**Example workflow:**
```bash
# Starting task: "Add lynx installation script"
# Step 1: Scan for similar scripts
Glob: install-scripts/*.sh

# Step 2: Read examples
Read: install-scripts/install-bat.sh
Read: install-scripts/install-fzf.sh

# Step 3: Identify pattern
# - Uses libs/utils.sh functions
# - Follows: check_installed → install → stow_package → link_shell_config → restow
# - Returns proper exit codes

# Step 4: Implement following the pattern
Write: install-scripts/install-lynx.sh (following discovered pattern)
```

## Core Principles

### 1. Modularity & Idempotency
- **One script per tool/component**: Each installation lives in its own script file in `install-scripts/`
- **Idempotent execution**: Safe to run on fresh installs or existing setups
- **Dependency-aware ordering**: Scripts execute in proper dependency order
- **Validation at each step**: Check if tool is needed, install, then validate it works

### 2. Configuration Management
- **GNU Stow for dotfiles**: All configurations managed via stow packages
- **XDG compliance**: Use `~/.config` and XDG standards whenever possible
- **Compartmentalization**: Separate stow package per concern (shell, tmux, nvim, git, etc.)
- **Dot-prefix notation**: Use stow's `dot-` filename convention (requires --dotfiles flag)
- **Existing config import**: Graceful handling of pre-existing configurations

### 3. Output & Error Handling
- **Consistent messaging**: Clear, formatted output at each step
- **Proper error propagation**: Scripts return errors correctly between components
- **Shared utilities**: Common formatting, colors, error handling via `libs/` includes
- **Non-intrusive libraries**: Favor lightweight external libraries like `bashlog` for logging

### 4. Platform Strategy
- **macOS focus**: Primary development target on `osx` branch
- **Future platform support**: Consider branch strategy vs unified scripts for Linux/Windows

## Architecture

### Directory Structure
```
devenv/
├── setup.sh                    # Main orchestrator script
├── install-scripts/            # Modular installation scripts
│   ├── install-homebrew.sh
│   ├── install-stow.sh
│   ├── install-tmux.sh
│   ├── install-nvim.sh
│   └── install-llm-cli.sh
├── libs/                       # Shared utilities
│   ├── logger.sh              # Logging functions (possibly bashlog)
│   ├── colors.sh              # Terminal colors/formatting
│   └── utils.sh               # Common validation functions
├── dotfiles/                  # Stow packages
│   ├── shell/                 # bash configurations
│   ├── tmux/                  # tmux configs and custom sessions
│   ├── nvim/                  # default neovim config
│   ├── lazyvim/               # lazyvim configuration
│   ├── git/                   # git configuration
│   └── [tool]/                # other tool configs
├── .env.example               # Template for environment secrets
├── .stowrc                    # Stow configuration
├── CLAUDE.md                  # This file
├── SETUP.md                   # Ordered list of what gets installed
├── WORKSPACE.md               # Tmux layout and workflow guide
└── PLANNING.md                # Execution roadmap
```

### Key Components

#### 1. Setup Infrastructure
- Modular install scripts with validation
- Shared utility libraries for consistent UX
- Platform detection and dependency management
- Clear progress reporting and error handling

#### 2. Core Tools Installation
- Development basics: git, stow, tmux, neovim, LLM CLIs
- Terminal productivity: fzf, ripgrep, bat, eza, zoxide, lazygit
- Language environments: Python (with venvs), Node.js, Ruby, etc.
- System tools: gdu, bottom, etc.

#### 3. Configuration Management
- Stow packages for each tool/concern
- XDG-compliant directory structure
- Environment variable management
- Backup and import of existing configs

#### 4. Tmux Workspace (Key Feature)
- **3-pane layout**: LLM CLI (left) | nvim (right) | prompt buffer (bottom)
- **Custom session management**: Open workspace in current/specified directory
- **Enhanced tmux setup**: Plugins, visual improvements, hotkey support
- **LLM integration**: Pipe between nvim prompt buffer and LLM CLI panes

#### 5. LLM Workflow Integration
- Support for modern LLM CLI chat clients (Claude Code, Gemini CLI, etc.)
- nvim buffer → tmux pane piping for prompt workflow
- Visual mode support for selected text prompting
- Future: Git-based conversation branching and context management

## Implementation Phases

### Phase 1: MVP Setup Infrastructure
- Core tool installation with modular scripts
- Basic tmux layout and configuration
- Stow-based dotfile management
- Validation and error handling

### Phase 2: LLM Integration
- LLM CLI installation and configuration
- Tmux workspace with prompt buffer workflow
- Keybindings and piping scripts
- Session management commands

### Phase 3: Advanced Features
- Git-based conversation branching
- Working tree state tracking
- Context reset capabilities
- Enhanced automation

## Development Guidelines

### Script Standards
- Include validation functions from `libs/`
- Check if installation is needed before proceeding
- Provide clear status messages using shared logging
- Return proper exit codes
- Test basic functionality after installation

#### Library Usage Priority
Always prefer existing library functionality over custom implementations:

1. **Use library first**: Check if bashlog or colr.sh already provides the functionality
2. **Adapt/improve library**: If library is close but needs tweaks, contribute improvements
3. **Custom implementation last resort**: Only write custom code when libraries cannot handle the use case

**Available libraries:**
- **bash-utility** (`libs/bash-utility/`): Comprehensive bash standard library (string, array, file, validation, etc.)
- **bashlog** (`libs/bashlog/`): Logging with levels (info, warn, error, debug), file output, syslog
- **colr.sh** (`libs/colr/`): Terminal colors with 256-color support
- **utils.sh** (`libs/utils.sh`): Project-specific utilities that leverage the above libraries

**See SHELL_SCRIPTING.md for comprehensive development guidelines.**

#### State-Based Execution (Ansible-Inspired Patterns)
Scripts should adopt these patterns for clarity and idempotency:

**State Reporting**: Each operation should report one of these states:
- **CHANGED**: Tool was installed or configuration was modified
- **OK**: Already in desired state, no action needed
- **SKIPPED**: Intentionally skipped due to conditions
- **FAILED**: Operation failed with error

**Skip Detection**: Explicitly check and report when operations are unnecessary:
```bash
if command_exists nvim; then
    log_ok "Neovim already installed ($(nvim --version | head -n1))"
    return 0
fi
```

**Dry-Run Support**: Consider implementing `--dry-run` or `--check` flag:
```bash
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "[DRY-RUN] Would install neovim via brew"
    return 0
fi
```

**Utility Functions**: Implement in `libs/utils.sh`:
```bash
report_changed()  # Something was installed/modified
report_ok()       # Already in desired state
report_skipped()  # Intentionally skipped
report_failed()   # Operation failed
check_installed() # Verify tool exists and return state
```

### Configuration Standards
- Follow XDG directory conventions
- Document important settings in package READMEs
- Maintain backward compatibility where possible
- Use environment variables for customization

### Documentation Standards
- Keep focused and actionable
- Document high-impact settings and workflows
- Maintain execution planning documents
- Provide troubleshooting guidance

### Testing Approach
- **Manual testing**: Run install scripts and verify behavior on actual system
- **Dry-run mode**: Test scripts with `DRY_RUN=true` to preview without changes
- **Idempotency testing**: Run scripts twice; second run should report "OK" states
- **Version checks**: Validate installation with `--version` or equivalent
- **Config verification**: Confirm stow packages apply correctly
- **Fresh environment testing**: Eventually test on clean macOS VM when possible

## Tools & Libraries

### Recommended Bash Libraries
- **bashlog**: Lightweight logging with levels, file output, debugging
- **colr.sh**: Terminal colors with 256-color support

### Environment Variables
- Source `.env` for secrets (API keys for LLM CLIs)
- Use `XDG_CONFIG_HOME` and related standards
- Maintain clean, tool-agnostic variable management

## Adding New Tools - Complete Workflow

When adding any new tool to DevEnv, follow this complete workflow:

### 1. Research & Selection
- **Evaluate the tool**: Does it serve a clear purpose? Is it actively maintained?
- **Check dependencies**: What other tools/libraries does it require?
- **Assess configuration**: Can it use XDG directories? Does it support theming?
- **Document decision**: Add justification to tool selection (e.g., "LazyVim dependency for LSP support")

### 2. Create Installation Script
- **Create**: `install-scripts/install-[tool].sh`
- **Follow patterns**: Use shared utilities from `libs/` for consistent output/error handling
- **Implement validation**: Check if installation needed, install, verify with `--version` or basic test
- **Handle dependencies**: Ensure prerequisite tools are installed first
- **Return proper exit codes**: Enable orchestration script to handle errors

### 3. Configuration Management
- **Create stow package**: `dotfiles/[tool]/` with proper `dot-` filename conventions
- **Apply theming**: Use Catppuccin color scheme where possible
- **Set fonts**: Use FiraCode Nerd Font as primary font choice
- **Follow XDG**: Place configs in `~/.config/[tool]/` when supported
- **Handle existing configs**: Import existing user configurations gracefully

#### Shell Configuration Pattern (CRITICAL)
**NEVER write directly to `dotfiles/shell/dot-shell.d/`**. Instead, follow this pattern:

1. **Create tool's shell config**: `dotfiles/[tool]/[tool].sh` in the tool's own directory
2. **Link via install script**: Use `link_shell_config "[tool]"` utility function
3. **Re-stow shell package**: Run `stow -R --dotfiles -t "${HOME}" shell` to apply

**Example from install-bat.sh:**
```bash
# Link bat shell configuration into shell.d/
log info "Configuring bat shell integration..."
if ! link_shell_config "bat"; then
  report_failed "Failed to link bat shell configuration"
  return 1
fi

# Re-stow shell package to include bat.sh symlink
local dotfiles_dir
dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
  report_changed "Applied bat shell configuration"
else
  report_failed "Failed to re-stow shell configuration"
  return 1
fi
```

**What happens:**
- `link_shell_config` creates symlink: `dotfiles/shell/dot-shell.d/[tool].sh` → `../../[tool]/[tool].sh`
- Re-stowing the shell package deploys the new symlink to `~/.shell.d/[tool].sh`
- `.bashrc` automatically sources all `.sh` files in `~/.shell.d/`

**Directory structure:**
```
dotfiles/
├── bat/
│   ├── bat.sh              # Shell config lives here
│   └── README.md
├── shell/
│   └── dot-shell.d/
│       └── bat.sh          # Symlink to ../../bat/bat.sh
```

### 4. Documentation & Integration
- **Update SETUP.md**: Add tool to appropriate phase with clear description and justification
- **Create package README**: `dotfiles/[tool]/README.md` documenting key settings and customizations
- **Update main orchestrator**: Add to `setup.sh` in correct dependency order
- **Document PATH changes**: Add any PATH modifications to dedicated `.bash_path` file

### 5. Validation & Testing
- **Test installation**: Verify on clean environment if possible
- **Test idempotency**: Ensure safe re-run when tool already installed
- **Test configuration**: Verify stow package applies correctly and tool uses new config
- **Test integration**: Ensure tool works with existing workflow (tmux, nvim, etc.)

### 6. Maintenance Considerations
- **Version pinning**: Consider if specific versions needed for stability
- **Update strategy**: How will tool updates be handled?
- **Removal strategy**: How to cleanly remove if no longer needed?
- **Backup strategy**: How to preserve user customizations during updates?

## Contributing

Focus on maintainability, clear documentation, and preserving the modular architecture. Each tool addition should follow the complete workflow above to ensure consistency and reliability across the development environment.