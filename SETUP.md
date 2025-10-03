# DevEnv Setup - Tool Installation Order

This document lists all tools and configurations installed by the DevEnv setup, organized in dependency order.

## Phase 1: Foundation Tools

### 1. Package Management
- **Homebrew** - macOS package manager, required for all other tool installations

### 2. Configuration Management
- **GNU Stow** - Symlink manager for dotfiles, enables modular configuration packages

## Phase 2: Core Development Tools

### 3. Version Control
- **Git** - Version control system, fundamental for development workflow

### 4. Text Editing & IDE
- **Neovim** - Modern vim-based editor, core of the development environment
- **LazyVim** - Neovim configuration with sane defaults and extensive plugin ecosystem

### 5. Terminal Multiplexing
- **Tmux** - Terminal multiplexer, enables the multi-pane workspace layout
- **Starship** - Cross-shell prompt with rich information display

### 6. Fonts & Theming
- **Nerd Fonts** - Programming fonts with icons and symbols support
- **FiraCode Nerd Font** - Primary font for editors and terminal
- **Catppuccin Theme** - Consistent color scheme across all tools

## Phase 3: Productivity Tools

### 7. File & Search Operations
- **fzf** - Fuzzy finder for files, command history, and interactive selection
- **ripgrep** - Fast text search tool, better than grep
- **fd** - Fast file finder, better than find
- **exa** - Modern replacement for ls with colors and git integration
- **bat** - Cat clone with syntax highlighting and git integration
- **yazi** - Terminal file manager

### 8. System Monitoring
- **gdu** - Disk usage analyzer with interactive interface
- **bottom** - System resource monitor (htop alternative)
- **htop** - Interactive process viewer

### 9. Navigation & History
- **zoxide** - Smart directory jumper (cd replacement)

### 10. Git Enhancement
- **lazygit** - Terminal UI for git with intuitive interface

## Phase 4: Language Environments

### 11. Python Environment
- **Python 3.13** - Latest Python version
- **Virtual Environments** - Separate venvs for each Neovim configuration:
  - `~/.venvs/nvim/` - Default Neovim Python provider
  - `~/.venvs/lazyvim/` - LazyVim Python provider
- **pynvim** - Python client for Neovim (installed in each venv)

### 12. Node.js Environment
- **Node.js** - JavaScript runtime (latest LTS)
- **npm packages**:
  - `neovim` - Node.js client for Neovim
  - `@mermaid-js/mermaid-cli` - Diagram generation tool

### 13. Ruby Environment
- **Ruby** - Ruby language runtime
- **rbenv** - Ruby version manager
- **Ruby 3.3.0** - Specific Ruby version for stability
- **neovim gem** - Ruby client for Neovim

### 14. Java Environment
- **OpenJDK** - Java development kit

### 15. Additional Languages (LazyVim Dependencies)
- **Rust** - Systems programming language (LSP and tool support)
- **Go** - Google's programming language (LSP and tool support)
- **Fish** - Alternative shell (required by some LazyVim plugins for enhanced terminal features)
- **PHP & Composer** - PHP language and package manager (LazyVim LSP support)
- **Julia** - Scientific computing language (LazyVim LSP support)

### 16. Perl Environment
- **Perl** - Perl language runtime
- **cpanminus** - Perl package installer
- **Perl Modules**:
  - `local::lib` - Local Perl library management
  - `MsgPack::Raw` - MessagePack serialization
  - `Neovim::Ext` - Perl client for Neovim

## Phase 5: Development Dependencies

### 17. Build & Analysis Tools (LazyVim Dependencies)
- **ast-grep** - Structural search and replace tool (LazyVim syntax parsing and refactoring)
- **luarocks** - Lua package manager (for Neovim Lua plugins)

### 18. Document Processing (LazyVim Dependencies)
- **ghostscript** - PostScript and PDF interpreter (LazyVim document rendering/preview)
- **tectonic** - Modern TeX/LaTeX engine (LazyVim LaTeX document compilation)

### 19. Font Support
- **fontconfig** - Font configuration library

## Phase 6: Configuration Packages (via Stow)

### 20. Shell Configuration
- **shell package** - `.bashrc`, `.bash_profile`, `.bash_aliases`, `.bash_functions`
- **PATH management** - Dedicated `.bash_path` file for all PATH modifications
- **bin scripts** - Custom utility scripts

### 21. Application Configurations
- **starship package** - Prompt configuration with Catppuccin theme
- **tmux package** - Terminal multiplexer settings with Catppuccin theme
- **git package** - Git configuration and aliases

### 22. Editor Configurations
- **nvim package** - Default Neovim configuration
- **lazyvim package** - LazyVim-specific settings and customizations with Catppuccin theme

## Phase 7: LLM Integration (Future)

### 23. LLM CLI Tools (To be added)
- **Claude Code CLI** - Anthropic's CLI interface
- **OpenAI CLI** - OpenAI's command-line interface
- **Gemini CLI** - Google's Gemini CLI interface
- **Other LLM CLIs** - Additional chat interfaces as they become available

### 24. Custom Workspace Tools (To be added)
- **tmux-llm-workspace** - Custom tmux session for LLM workflow
- **nvim-prompt-buffer** - Prompt management utilities
- **tmux-pane-pipe** - Scripts for piping between tmux panes

## Installation Validation

Each tool installation includes validation steps:
- **Pre-check**: Verify if tool needs installation
- **Installation**: Install via appropriate method (brew, npm, pip, etc.)
- **Post-check**: Validate installation with `--version` or basic functionality test
- **Configuration**: Apply configurations via Stow where applicable
- **Config validation**: Verify configuration files are properly linked/applied

## Environment Variables

### Required Environment Setup
- **PATH additions**: Homebrew, language tools, custom bin directory
- **XDG directories**: `XDG_CONFIG_HOME=~/.config`
- **Language-specific**: Ruby, Python, Node.js, Perl PATH additions
- **Tool-specific**: fzf key bindings, completion setup

### Secret Management
- **API Keys**: Stored in `.env` file (not committed)
- **Template**: `.env.example` provided for reference
- **Usage**: Sourced by shell configuration for LLM CLI authentication

## Post-Installation Requirements

### Manual Steps
1. **Restart terminal** or source `~/.bash_profile`
2. **Configure existing settings import** during stow
3. **Configure API keys** in `.env` file
4. **Test Neovim configurations**:
   - `nvim` - Default configuration
   - `lazyvim` - LazyVim configuration

### Health Checks
- Run `:checkhealth` in each Neovim configuration
- Test tmux session creation and restoration
- Verify font installation and Catppuccin theming
- Confirm all language providers are working