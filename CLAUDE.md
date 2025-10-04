# DevEnv - AI Assistant Guidelines

## Project Overview

This is a terminal-based development environment bootstrapping utility that creates a complete, reproducible development setup. The environment centers around a tmux-based workspace integrating LLM CLI tools with nvim for enhanced productivity.

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
- **Dot-prefix notation**: Use stow's `dot_` filename convention
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
- Minimal validation that confirms tool readiness
- `--version` checks after installation
- Basic config application verification after stow
- Consider BATS for future automated testing

## Tools & Libraries

### Recommended Bash Libraries
- **bashlog**: Lightweight logging with levels, file output, debugging
- **colr.sh**: Terminal colors with 256-color support
- **BATS-Core**: Testing framework for future automated tests

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
- **Create stow package**: `dotfiles/[tool]/` with proper `dot_` filename conventions
- **Apply theming**: Use Catppuccin color scheme where possible
- **Set fonts**: Use FiraCode Nerd Font as primary font choice
- **Follow XDG**: Place configs in `~/.config/[tool]/` when supported
- **Handle existing configs**: Import existing user configurations gracefully

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