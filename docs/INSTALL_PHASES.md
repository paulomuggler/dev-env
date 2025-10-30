# DevEnv Installation Phases

This document lists all tools installed by `setup.sh` organized by phase.

## Usage

```bash
# Standard installation (Phases 1-5 + Phase 6 on macOS)
./setup.sh

# Skip confirmation prompt
./setup.sh --yes

# Include optional LLM CLI tools (adds Phase 7)
./setup.sh --llm

# Both options
./setup.sh --yes --llm
```

## Phase 1: Foundation

**Package Manager & Configuration Management**

- `homebrew` (macOS only) - Package manager
- `stow` - Symlink farm manager for dotfiles

## Phase 2: Shell Configuration

**Shell Environment Setup**

- `shell` - Bash configuration and dotfiles

## Phase 3: Core Tools

**Essential Development Tools**

- `git` - Version control system
- `gh` - GitHub CLI
- `nerd-fonts` - Patched fonts with icons (required for starship, nvim, etc.)
- `starship` - Cross-shell prompt
- `tmux` - Terminal multiplexer with Oh my tmux! configuration

## Phase 4: CLI Productivity Tools

**Modern Replacements for Unix Tools**

- `bat` - Better `cat` with syntax highlighting
- `eza` - Better `ls` with colors and git integration
- `fd` - Better `find`
- `ripgrep` - Better `grep`
- `sd` - Better `sed`
- `dust` - Better `du` (disk usage)
- `duf` - Better `df` (disk free)
- ~~`dog` - Better `dig` (DNS lookup)~~ *(DISABLED: brew formula dead)*
- `xh` - Better `httpie` (HTTP client)

**Navigation & Search**

- `fzf` - Fuzzy finder
- `zoxide` - Smart `cd` command

**Development Tools**

- `lazygit` - Git TUI
- `ast-grep` - Structural code search and replace

**File Management**

- `yazi` - Terminal file manager

**System Monitoring**

- `bottom` - System monitor (btm)
- `gdu` - Fast disk usage analyzer
- `ncdu` - NCurses disk usage analyzer
- `htop` - Interactive process viewer

**Utilities**

- `tree` - Directory tree viewer
- `jq` - JSON processor
- `glow` - Markdown renderer
- `lynx` - Text-based web browser

**Compression Tools**

- `xz` - XZ compression
- `zstd` - Zstandard compression
- `p7zip` - 7-Zip compression
- `unrar` - RAR extraction

## Phase 5: Development Environment

**Language Environments**

- `pyenv` - Python version manager
- `node` - Node.js runtime
- `rbenv` - Ruby version manager
- `dotnet` - .NET SDK

**Editor & LLM Integration**

- `nvim` - Neovim with LazyVim
- `lazyllm` - LLM CLI integration for tmux workflows

## Phase 6: Optional macOS Tools

**macOS-Specific Applications**

*(Only runs on macOS, safely skipped on other platforms)*

- `iterm2` - Modern terminal emulator
- `aerospace` - i3-like tiling window manager

## Phase 7: Optional LLM CLI Tools

**LLM Command-Line Interfaces**

*(Only installs if `--llm` flag is provided)*

- `claude-code` - Claude Code CLI
- `gemini-cli` - Google Gemini CLI
- `grok-cli` - Grok CLI
- `openai-codex` - OpenAI Codex CLI

---

## Summary Statistics

- **Phase 1**: 2 tools (1 on macOS, 2 on Linux)
- **Phase 2**: 1 package
- **Phase 3**: 5 tools
- **Phase 4**: 28 tools
- **Phase 5**: 6 tools
- **Phase 6**: 2 tools (macOS only)
- **Phase 7**: 4 tools (optional)

**Total**: 48 tools (44 default + 2 macOS + 4 optional LLM)

> **Note**: `dog` (DNS lookup tool) is currently disabled due to broken brew formula. Use built-in `dig` or consider `doggo` as an alternative.

## Installation Order

The phases are run in order to respect dependencies:

1. Package manager must be available first
2. Shell configuration provides the environment
3. Core tools (git, fonts) needed by other phases
4. CLI tools can be installed in any order
5. Development tools may depend on earlier phases
6. Optional tools installed last

## Skipping Tools

If an install script is not found or not executable, it will be skipped and reported in the summary. The installation continues with remaining tools.

## Manual Installation

You can also run individual install scripts:

```bash
# Install a single tool
./install-scripts/install-bat.sh

# Install a group of tools
./install-scripts/install-{bat,eza,fd}.sh
```
