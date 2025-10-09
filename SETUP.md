# DevEnv Setup - Tool Installation Order

This document lists all tools and configurations installed by the DevEnv setup, organized in dependency order.

## Current Status

### Completed Integrations (shell.d/ Pattern)
Tools following the modular shell configuration pattern:
- ✅ **bat** - Cat replacement with syntax highlighting
- ✅ **eza** - Modern ls replacement
- ✅ **fzf** - Fuzzy finder with key bindings
- ✅ **git** - Shell aliases and functions
- ✅ **starship** - Cross-shell prompt
- ✅ **zoxide** - Smart directory navigation

**All legacy tool migrations complete!** The shell.d/ pattern is now fully established.

### Shell Configuration Architecture

**Sourcing Order in `.bashrc`:**
1. `.bash_env` - Environment variables
2. `.bash_aliases` - General-purpose aliases (fallbacks)
3. `.bash_functions` - General-purpose functions
4. **`.shell.d/*.sh`** - Tool-specific configs (override defaults)
5. Legacy tool initializations (to be migrated)

**Key Design Principle:**
`.shell.d/` configs are sourced AFTER `.bash_aliases` and `.bash_functions`. This allows:
- Fallback defaults in `.bash_aliases` (e.g., `ll='ls -la'`)
- Tool-specific overrides via `.shell.d/` (e.g., `ll='eza -la --git --icons'`)
- Tools work even if not installed (fallback to standard commands)

**Tool Package Structure:**
```
dotfiles/<tool>/
├── <tool>.sh              # Shell integration (symlinked to .shell.d/)
├── .config/<tool>/config  # Config files (stowed to ~/.config/)
├── dot-<file>            # Home dotfiles (stowed to ~/)
└── README.md             # Tool documentation
```

## Phase 1: Foundation Tools

### 1. Package Management
- **Homebrew** - macOS package manager, required for all other tool installations

### 2. Configuration Management
- **GNU Stow** - Symlink manager for dotfiles, enables modular configuration packages

## Phase 2: Core Development Tools

### 3. Version Control
- **Git** - Version control system, fundamental for development workflow (✅ integrated)

### 4. Text Editing & IDE
- **Neovim** - Modern vim-based editor, core of the development environment
- **LazyVim** - Neovim configuration with sane defaults and extensive plugin ecosystem

### 5. Terminal Multiplexing
- **Tmux** - Terminal multiplexer, enables the multi-pane workspace layout
- **Starship** - Cross-shell prompt with rich information display (✅ integrated)

### 6. Fonts & Theming
- **Nerd Fonts** - Programming fonts with icons and symbols support
- **FiraCode Nerd Font** - Primary font for editors and terminal
- **Catppuccin Theme** - Consistent color scheme across all tools

## Phase 3: Productivity Tools

### 7. File & Search Operations
- **fzf** - Fuzzy finder for files, command history, and interactive selection (✅ integrated)
- **ripgrep** - Fast text search tool, better than grep
- **fd** - Fast file finder, better than find
- **tree** - Display directory structure in tree format
- **jq** - Command-line JSON processor for parsing and formatting
- **eza** - Modern replacement for ls with colors and git integration (✅ integrated)
- **bat** - Cat clone with syntax highlighting and git integration (✅ integrated)
- **yazi** - Terminal file manager
- **glow** - Markdown preview in terminal, used by glow.nvim plugin (`:Glow` command)
- **lynx** - Text-based web browser, required by CopilotChat.nvim for documentation lookup

### 7a. Markdown Rendering
- **glow.nvim** - Terminal-based markdown preview with `:Glow` command
- **markview.nvim** - Enhanced in-buffer markdown rendering with tree-sitter (automatic preview)

### 8. System Monitoring
- **gdu** - Disk usage analyzer with interactive interface
- **bottom** - System resource monitor (htop alternative)
- **htop** - Interactive process viewer

### 9. Navigation & History
- **zoxide** - Smart directory jumper (cd replacement) (✅ integrated)

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

### 20. LSP Servers & Development Tools
All LSP servers are auto-installed by Mason when first launching Neovim. Configured in `dotfiles/nvim/.config/nvim/lua/plugins/lsp.lua`:

**Language Servers:**
- **lua-language-server** - Lua LSP
- **typescript-language-server** - JavaScript/TypeScript LSP
- **pyright** - Python LSP with type checking
- **terraformls** - Terraform/HCL LSP
- **ansible-language-server** - Ansible YAML LSP
- **html-lsp** - HTML LSP
- **css-lsp** - CSS LSP
- **json-lsp** - JSON LSP
- **yaml-language-server** - YAML LSP with schema validation
- **bash-language-server** - Bash/Shell LSP
- **omnisharp** - C# LSP (.NET)
- **clangd** - C/C++ LSP with advanced features
- **marksman** - Markdown LSP

**Formatters:**
- **prettier** - Multi-language formatter (JS/TS/HTML/CSS/JSON/YAML)
- **stylua** - Lua formatter
- **black** - Python formatter (PEP 8)
- **isort** - Python import sorter
- **shfmt** - Shell script formatter
- **terraform-fmt** - Terraform formatter

**Linters:**
- **eslint_d** - JavaScript/TypeScript linter (fast daemon)
- **pylint** - Python linter
- **shellcheck** - Shell script linter
- **yamllint** - YAML linter
- **ansible-lint** - Ansible playbook linter

**Usage:**
- Run `:Mason` in Neovim to view and manage LSP servers
- Run `:LspInfo` to see active LSP servers for current buffer
- Run `:checkhealth mason` to verify Mason installation

## Phase 6: Configuration Packages (via Stow)

### 20. Shell Configuration
- **shell package** - `.bashrc`, `.bash_profile`, `.bash_aliases`, `.bash_functions` (✅ integrated)
- **shell.d/ pattern** - Modular tool-specific configurations (✅ integrated)
- **PATH management** - Dedicated `.bash_path` file for all PATH modifications
- **bin scripts** - Custom utility scripts

### 21. Application Configurations
- **starship package** - Prompt configuration with Gruvbox theme (✅ integrated with shell.d/)
- **tmux package** - Terminal multiplexer settings with Catppuccin theme
- **git package** - Git configuration and aliases (✅ integrated with shell.d/)
- **bat package** - Syntax highlighting configuration (✅ integrated with shell.d/)
- **eza package** - Modern ls aliases and configuration (✅ integrated with shell.d/)
- **fzf package** - Fuzzy finder configuration (✅ integrated with shell.d/)
- **zoxide package** - Smart navigation configuration (✅ integrated with shell.d/)

### 22. Editor Configurations
- **nvim package** - Default Neovim configuration
- **lazyvim package** - LazyVim-specific settings and customizations with Catppuccin theme

## Phase 7: LLM Integration

### 23. LLM CLI Tools
Modern agentic TUI tools for AI-assisted development. These tools integrate with lazy-llm for seamless tmux-based workflows.

- **Claude Code** - Anthropic's agentic coding assistant (Node.js 18+)
  - Install: `npm install -g @anthropic-ai/claude-code`
  - Command: `claude`
  - Authentication: OAuth flow on first launch
  - Features: Read/modify/run code, git workflows, natural language commands
  - Integration: `lazy-llm -t claude`

- **Gemini CLI** - Google's AI agent for terminal (Node.js 20+)
  - Install: `npm install -g @google/gemini-cli`
  - Command: `gemini`
  - Authentication: Google account
  - Features: 1M token context, Google Search grounding, MCP support
  - Free tier: 60 req/min, 1000 req/day
  - Integration: `lazy-llm -t gemini`

- **OpenAI Codex** - OpenAI's lightweight coding agent
  - Install: `npm install -g @openai/codex`
  - Command: `codex`
  - Authentication: Sign in with ChatGPT (Plus users: $50 credits, Free: $5 credits)
  - Features: Local code operations, latest reasoning models
  - Platform: macOS/Linux (Windows via WSL)
  - Integration: `lazy-llm -t codex`

- **Grok CLI** - xAI's AI agent for terminal (Node.js 18+)
  - Install: `npm install -g @vibe-kit/grok-cli`
  - Command: `grok`
  - Authentication: xAI API key
  - Features: 1M token context, natural language operations
  - Models: grok-code-fast-1, grok-4-latest, grok-3-fast
  - Integration: `lazy-llm -t grok`

### 24. Custom Workspace Tools
- **lazy-llm** - Tmux + Neovim workflow for AI-assisted development (✅ installed)
  - Three-pane layout: AI tool, editor, prompt buffer
  - Send prompts from buffer to AI with keybindings
  - Git integration for change tracking
  - File reference autocomplete with `@` symbol
  - Usage: `lazy-llm [-s session] [-d directory] [-t ai_tool]`

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