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
- **AstroNvim** - Community-driven Neovim configuration with additional features

### 5. Terminal Multiplexing
- **Tmux** - Terminal multiplexer, enables the multi-pane workspace layout
- **Starship** - Cross-shell prompt with rich information display

### 6. Terminal Applications
- **Kitty** - GPU-accelerated terminal emulator with hotkey window support
- **WezTerm** - Alternative terminal with advanced features and image protocol support

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
  - `~/.venvs/astronvim/` - AstroNvim Python provider
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

### 15. Additional Languages
- **Rust** - Systems programming language
- **Go** - Google's programming language
- **Fish** - Alternative shell (for certain Neovim plugins)
- **PHP & Composer** - PHP language and package manager
- **Julia** - Scientific computing language

### 16. Perl Environment
- **Perl** - Perl language runtime
- **cpanminus** - Perl package installer
- **Perl Modules**:
  - `local::lib` - Local Perl library management
  - `MsgPack::Raw` - MessagePack serialization
  - `Neovim::Ext` - Perl client for Neovim

## Phase 5: Development Dependencies

### 17. Build & Analysis Tools
- **ast-grep** - Structural search and replace tool
- **luarocks** - Lua package manager (for Neovim plugins)

### 18. Document Processing
- **ghostscript** - PostScript and PDF interpreter
- **tectonic** - Modern TeX/LaTeX engine

### 19. Font Support
- **fontconfig** - Font configuration library

## Phase 6: Automation & Productivity

### 20. macOS Automation
- **Hammerspoon** - macOS automation tool for hotkeys and window management
  - Provides double-tap hotkeys (Cmd-Cmd, Alt-Alt, Ctrl-Ctrl)
  - Fallback hotkey: Cmd+Shift+Space
  - Requires accessibility permissions

## Phase 7: Configuration Packages (via Stow)

### 21. Shell Configuration
- **bash package** - `.bashrc`, `.bash_profile`, `.bash_aliases`, `.bash_functions`
- **bin scripts** - Custom utility scripts including `kitty-hotkey`

### 22. Application Configurations
- **starship package** - Prompt configuration
- **tmux package** - Terminal multiplexer settings
- **kitty package** - Terminal emulator configuration
- **wezterm package** - Alternative terminal configuration
- **hammerspoon package** - macOS automation scripts

### 23. Editor Configurations
- **nvim package** - Default Neovim configuration
- **lazyvim package** - LazyVim-specific settings and customizations
- **astronvim package** - AstroNvim-specific settings and customizations

## Phase 8: LLM Integration (Future)

### 24. LLM CLI Tools (To be added)
- **Claude Code CLI** - Anthropic's CLI interface
- **OpenAI CLI** - OpenAI's command-line interface
- **Gemini CLI** - Google's Gemini CLI interface
- **Other LLM CLIs** - Additional chat interfaces as they become available

### 25. Custom Workspace Tools (To be added)
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
2. **Grant accessibility permissions** to Hammerspoon
3. **Configure API keys** in `.env` file
4. **Test Neovim configurations**:
   - `nvim` - Default configuration
   - `lazyvim` - LazyVim configuration
   - `astrovim` - AstroNvim configuration

### Health Checks
- Run `:checkhealth` in each Neovim configuration
- Test tmux session creation and restoration
- Verify terminal hotkey functionality
- Confirm all language providers are working