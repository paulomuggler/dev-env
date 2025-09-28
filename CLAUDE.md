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

## Contributing

When adding new tools or features:
1. Create modular install script in `install-scripts/`
2. Add stow package in `dotfiles/[tool]/`
3. Include README.md with package documenting key settings
4. Update SETUP.md with tool description
5. Use shared utilities from `libs/` for consistency
6. Test on clean environment when possible

Focus on maintainability, clear documentation, and preserving the modular architecture.