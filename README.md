# DevEnv - Automated Development Environment Setup

A comprehensive, reproducible development environment setup for macOS, Ubuntu, and Arch Linux. Built with modular shell scripts, GNU Stow for configuration management, and a tmux-based AI-assisted workflow.

## 🎯 Overview

DevEnv automates the installation and configuration of a complete terminal-based development environment featuring:

- **Modern CLI tools**: fzf, ripgrep, bat, eza, zoxide, lazygit, and more
- **Neovim with LazyVim**: Full-featured IDE with LSP support and extensive plugins
- **Tmux workspace**: Multi-pane layouts optimized for development workflows
- **AI integration**: Claude Code, Gemini CLI, OpenAI Codex, and Grok CLI with custom tmux workflows
- **Cross-platform**: Single codebase supporting macOS, Ubuntu, and Arch Linux
- **Version-controlled configurations**: All dotfiles managed via GNU Stow
- **Modular architecture**: Each tool has its own installation script and configuration package

## ✨ Key Features

### 🔧 Modular Installation Scripts
Each tool has a dedicated install script with:
- Idempotent execution (safe to run multiple times)
- Platform-agnostic package management
- Validation and error handling
- Ansible-inspired state reporting (CHANGED/OK/FAILED/SKIPPED)

### 📦 Configuration Management
- **GNU Stow**: Symlink-based dotfile management
- **XDG compliance**: Follows `~/.config` standards
- **Modular packages**: Separate configuration for each tool
- **Shell.d pattern**: Tool-specific shell configs in `~/.shell.d/`

### 🎨 Consistent Theming
- **Catppuccin**: Unified color scheme across all tools
- **FiraCode Nerd Font**: Programming font with icon support
- **iTerm2**: Custom preferences with version control

### 🤖 AI-Assisted Development
- **lazy-llm**: Custom tmux workflow for AI-assisted coding
- **Multiple AI tools**: Support for Claude, Gemini, Codex, Grok
- **Prompt buffer**: Send code and prompts to AI from nvim
- **Git integration**: Track changes during AI sessions

## 🚀 Quick Start

### Prerequisites

- **macOS**: 12.0+ (Monterey or later)
- **Ubuntu**: 20.04+ (or Debian-based distributions)
- **Arch Linux**: Current rolling release

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/dev-env.git ~/Projects/dev-env
cd ~/Projects/dev-env

# Run the main setup script
./setup.sh

# Or run in dry-run mode to preview changes
DRY_RUN=true ./setup.sh
```

The setup script will:
1. Install foundation tools (Homebrew on macOS, package manager verification)
2. Install core development tools (Git, Neovim, Tmux, Starship)
3. Install productivity tools (fzf, ripgrep, bat, eza, zoxide, lazygit)
4. Set up language environments (Python, Node.js, Ruby, .NET)
5. Apply dotfile configurations via GNU Stow
6. Configure shell integration for all tools

### Post-Installation

```bash
# Restart your terminal or source the shell configuration
source ~/.bash_profile

# Verify installation
nvim --version
tmux -V
starship --version

# Check Neovim health
nvim +checkhealth
```

## 📁 Repository Structure

```
dev-env/
├── setup.sh                    # Main orchestrator script
├── install-scripts/            # Modular installation scripts
│   ├── install-homebrew.sh    # Package manager (macOS)
│   ├── install-stow.sh        # Configuration management
│   ├── install-nvim.sh        # Neovim + LazyVim
│   ├── install-tmux.sh        # Terminal multiplexer
│   ├── install-fzf.sh         # Fuzzy finder
│   ├── install-starship.sh    # Shell prompt
│   └── ...                    # 35+ tool install scripts
├── dotfiles/                  # GNU Stow packages
│   ├── shell/                 # Bash configurations
│   │   ├── dot-bashrc        # Interactive shell config
│   │   ├── dot-bash_profile  # Login shell config
│   │   ├── dot-bash_path     # PATH management
│   │   └── dot-shell.d/      # Tool config symlinks
│   ├── nvim/                  # Default Neovim config
│   ├── lazyvim/               # LazyVim configuration
│   ├── tmux/                  # Tmux configuration
│   ├── git/                   # Git configuration
│   ├── starship/              # Prompt configuration
│   ├── iterm2/                # iTerm2 preferences (macOS)
│   └── [tool]/                # Individual tool configs
├── libs/                      # Shared utilities
│   ├── linker.sh             # Library loader
│   ├── platform.sh           # Platform abstraction
│   ├── utils.sh              # Helper functions
│   ├── bashlog/              # Logging library
│   ├── bash-utility/         # Bash standard library
│   └── colr/                 # Terminal colors
├── external/                  # Git submodules
│   └── lazy-llm/             # AI workflow tool
├── bin/                       # Custom scripts
│   └── custom utilities
├── .env.example              # Environment variables template
├── SETUP.md                  # Detailed tool list and phases
├── CLAUDE.md                 # AI assistant guidelines
├── SHELL_SCRIPTING.md        # Development conventions
└── README.md                 # This file
```

## 🛠️ Core Tools

### Foundation
- **Homebrew** (macOS) - Package manager
- **GNU Stow** - Dotfile symlink manager

### Development
- **Neovim** - Modern vim-based editor
- **LazyVim** - Neovim distribution with sane defaults
- **Tmux** - Terminal multiplexer
- **Git** - Version control

### Productivity
- **fzf** - Fuzzy finder for files, history, commands
- **ripgrep** - Fast text search (better grep)
- **fd** - Fast file finder (better find)
- **bat** - Cat with syntax highlighting
- **eza** - Modern ls replacement with git integration
- **zoxide** - Smart directory navigation (better cd)
- **lazygit** - Terminal UI for git
- **Starship** - Fast, customizable shell prompt

### Languages & Runtimes
- **Python** (pyenv) - Python version manager
- **Node.js** - JavaScript runtime
- **Ruby** (rbenv) - Ruby version manager
- **.NET SDK** - C# development platform

### System Utilities
- **gdu** - Disk usage analyzer
- **bottom** - System resource monitor
- **htop** - Process viewer
- **jq** - JSON processor
- **tree** - Directory tree viewer

### AI Tools
- **Claude Code** - Anthropic's coding assistant
- **Gemini CLI** - Google's AI agent
- **OpenAI Codex** - OpenAI's coding agent
- **Grok CLI** - xAI's terminal agent
- **lazy-llm** - Custom tmux AI workflow

See [SETUP.md](SETUP.md) for the complete list of 70+ tools and installation phases.

## 📚 Documentation

- **[SETUP.md](SETUP.md)** - Complete tool list with installation phases and dependencies
- **[CLAUDE.md](CLAUDE.md)** - AI assistant development guidelines and project conventions
- **[SHELL_SCRIPTING.md](SHELL_SCRIPTING.md)** - Bash scripting best practices and library usage
- **[PLANNING.md](PLANNING.md)** - Implementation roadmap and feature planning
- **Individual READMEs** - Each `dotfiles/[tool]/` package has its own documentation

## 🎨 Theming

### Catppuccin Color Scheme
Consistent theming across all tools:
- **Tmux**: Catppuccin status line with custom segments
- **Neovim/LazyVim**: Catppuccin Mocha theme
- **bat**: Catppuccin syntax highlighting
- **fzf**: Catppuccin color scheme

### Fonts
- **FiraCode Nerd Font**: Primary font with ligatures and icon support
- Installed via `install-scripts/install-nerd-fonts.sh`
- Configure in terminal emulator and Neovim

## 🔧 Configuration Management

### Shell Configuration Architecture

```
~/.bash_profile        # Login shell (sources .bashrc and .bash_path)
  ├── ~/.bash_path     # PATH management (Homebrew, language tools)
  └── ~/.bashrc        # Interactive shell config
      ├── ~/.bash_env  # Environment variables (optional)
      ├── ~/.bash_aliases  # General aliases (fallback defaults)
      ├── ~/.bash_functions  # General functions
      └── ~/.shell.d/*.sh  # Tool-specific configs (override defaults)
```

### Tool Configuration Pattern

Each tool follows this structure:

```
dotfiles/[tool]/
├── [tool].sh                      # Shell integration
├── .config/[tool]/config          # XDG-compliant config
├── dot-[file]                     # Home directory dotfile
└── README.md                      # Tool documentation
```

Installation scripts:
1. Install the tool via package manager
2. Link `[tool].sh` into `dotfiles/shell/dot-shell.d/`
3. Stow the tool's configuration package
4. Re-stow shell package to activate symlinks

### Stow Safety

All scripts use the `stow_package()` utility function which:
- Creates backups of existing configurations
- Detects and handles conflicts
- Supports adopt mode for importing existing configs
- Prevents accidental overwrites

## 🚀 Usage

### Running Individual Install Scripts

```bash
# Install a specific tool
cd ~/Projects/dev-env
./install-scripts/install-fzf.sh

# Dry-run mode (preview without changes)
DRY_RUN=true ./install-scripts/install-nvim.sh

# Check if tool needs installation
./install-scripts/install-git.sh
# Output: [OK] git is already installed (version 2.43.0)
```

### Managing Configurations

```bash
# Apply a configuration package
cd ~/Projects/dev-env/dotfiles
stow -t "${HOME}" --dotfiles [package-name]

# Remove a configuration
stow -D -t "${HOME}" --dotfiles [package-name]

# Adopt existing configuration
stow --adopt -t "${HOME}" --dotfiles [package-name]
```

### Shell Integration

Tool-specific configurations are automatically loaded:

```bash
# After installing a tool, restart shell or source config
source ~/.bashrc

# Tool configs are in ~/.shell.d/
ls -la ~/.shell.d/
# bat.sh -> ../Projects/dev-env/dotfiles/bat/bat.sh
# fzf.sh -> ../Projects/dev-env/dotfiles/fzf/fzf.sh
# git.sh -> ../Projects/dev-env/dotfiles/git/git.sh
```

### AI-Assisted Development

```bash
# Launch AI workflow (default: Claude Code)
lazy-llm

# Use specific AI tool
lazy-llm -t gemini

# Work in specific directory
lazy-llm -d ~/Projects/my-project

# Named session
lazy-llm -s my-feature

# Combined options
lazy-llm -s bugfix -d ~/Projects/app -t claude
```

Inside the workflow:
- **Left pane**: AI assistant (Claude, Gemini, etc.)
- **Right pane**: Neovim editor
- **Bottom pane**: Prompt buffer for composing AI requests
- Press configured keybinding to send prompt to AI
- Use `@filename` for file reference autocomplete

## 🌍 Platform Support

### macOS (Primary Target)
- Full support for all features
- Homebrew package installation
- iTerm2 configuration management
- Tested on macOS 12.0+ (Monterey and later)

### Ubuntu/Debian
- Complete tool support
- apt package manager integration
- Handles package naming differences (bat→batcat, fd→fdfind)
- Python venv dependencies auto-installed
- Some packages unavailable in apt (documented in SETUP.md)

### Arch Linux
- pacman integration
- Full tool support planned
- Currently under development

### Platform Abstraction

The `libs/platform.sh` library provides:
- **Platform detection**: `get_platform()` returns macos/ubuntu/arch
- **Package management**: `pkg_install()`, `pkg_update()`, `pkg_installed()`
- **Package name mapping**: Cross-platform package name resolution
- **Validation**: `validate_platform()` checks platform support

## 🧪 Testing

```bash
# Test on current system
./setup.sh

# Dry-run mode (no changes)
DRY_RUN=true ./setup.sh

# Test individual script
DRY_RUN=true ./install-scripts/install-bat.sh

# Verify idempotency (run twice, second should report OK)
./install-scripts/install-fzf.sh
./install-scripts/install-fzf.sh
# Second run: [OK] fzf is already installed
```

## 🔍 Troubleshooting

### Installation Issues

```bash
# Check if Homebrew is working (macOS)
brew doctor

# Verify package manager (Ubuntu)
sudo apt update
sudo apt-cache search [package-name]

# Check install script logs
./install-scripts/install-[tool].sh
# Scripts provide detailed output with [INFO], [WARN], [ERROR] prefixes
```

### Configuration Issues

```bash
# Check stow conflicts
cd ~/Projects/dev-env/dotfiles
stow -n -v -t "${HOME}" --dotfiles [package]

# View existing symlinks
ls -la ~/.config/[tool]/

# Check shell.d integration
ls -la ~/.shell.d/
source ~/.bashrc
```

### Neovim Issues

```bash
# Run health checks
nvim +checkhealth

# Check specific provider
nvim +checkhealth provider

# Verify Python provider
python3 -m pip list | grep pynvim

# Check LSP servers
nvim +Mason
```

### PATH Issues

```bash
# Verify PATH includes all tools
echo $PATH

# Check bash_path
cat ~/.bash_path

# Re-source configuration
source ~/.bash_profile
```

## 🤝 Contributing

### Adding New Tools

Follow the complete workflow in [CLAUDE.md](CLAUDE.md#adding-new-tools---complete-workflow):

1. **Research & Selection**: Evaluate tool and dependencies
2. **Create Install Script**: Follow existing patterns in `install-scripts/`
3. **Create Configuration Package**: Set up `dotfiles/[tool]/` structure
4. **Shell Integration**: Use `link_shell_config()` utility
5. **Documentation**: Add README and update SETUP.md
6. **Testing**: Verify installation and idempotency

### Development Guidelines

See [SHELL_SCRIPTING.md](SHELL_SCRIPTING.md) for:
- Bash scripting best practices
- Library usage (bashlog, bash-utility, platform abstraction)
- Error handling patterns
- State-based execution (Ansible-inspired)
- Testing approaches

### Code Style

- Use `set -euo pipefail` in all scripts
- Prefer library functions over custom implementations
- Follow existing naming conventions
- Document all functions and complex logic
- Include validation at each step
- Return proper exit codes

## 📜 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

### Libraries & Tools
- **bashlog** - Lightweight logging with levels
- **bash-utility** - Comprehensive bash standard library
- **colr.sh** - Terminal color support
- **GNU Stow** - Symlink farm manager

### Inspiration
- **LazyVim** - Neovim distribution
- **Catppuccin** - Soothing color scheme
- **Nerd Fonts** - Icon-enhanced fonts
- **Modern Unix** - Collection of modern CLI alternatives

## 📮 Support

- **Issues**: Report bugs and request features on GitHub Issues
- **Discussions**: Join GitHub Discussions for questions and ideas
- **Documentation**: Check the docs in this repo first

## 🗺️ Roadmap

See [PLANNING.md](PLANNING.md) for detailed roadmap. Upcoming features:

- **Phase 1**: ✅ MVP setup infrastructure (complete)
- **Phase 2**: ✅ Multiplatform support (complete)
- **Phase 3**: 🚧 Enhanced LLM integration
  - Git-based conversation branching
  - Context reset capabilities
  - Working tree state tracking
- **Phase 4**: 🔜 Windows WSL support
- **Phase 5**: 🔜 Docker containerized environments

---

**Built with ❤️ for developers who live in the terminal**
