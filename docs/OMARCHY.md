# DevEnv for Omarchy (Arch Linux + Hyprland)

This document covers setting up dev-env on [Omarchy](https://omarchy.org/), DHH's opinionated Arch Linux + Hyprland distribution.

## Overview

Omarchy already provides an excellent base with 147+ packages. DevEnv adds:

- **tmux + lazy-llm** - AI-assisted development workflow
- **Additional CLI tools** - ast-grep, gdu, htop, glow, etc.
- **LLM CLI tools** - claude-code, gemini-cli, grok-cli
- **Remote access stack** - Sunshine + Moonlight, NoMachine
- **Headless configuration** - Virtual display, auto-login

## Quick Start

```bash
# Clone dev-env
git clone https://github.com/your-repo/dev-env.git ~/dev-env
cd ~/dev-env

# Basic setup (core tools + lazy-llm)
./setup-omarchy.sh

# Full setup (includes remote access + headless)
./setup-omarchy.sh --all

# Preview without changes
DRY_RUN=true ./setup-omarchy.sh --all
```

## What's Already in Omarchy (Not Installed)

These tools are included in Omarchy by default:

| Category | Tools |
|----------|-------|
| Terminal | Ghostty (with dropdown support!) |
| Shell | bat, eza, fd, ripgrep, fzf, zoxide, jq, dust, tldr |
| Git | lazygit, github-cli |
| Editor | Neovim with LazyVim (omarchy-nvim) |
| Prompt | Starship |
| System | btop, grim, slurp, wl-clipboard |
| Dev | Docker, docker-compose, Ruby, Rust, mise |
| Fonts | JetBrains Mono Nerd, Cascadia Mono Nerd |

## What DevEnv Adds

### Core Workflow
- **tmux** - Terminal multiplexer (not in Omarchy)
- **lazy-llm** - 3-pane LLM workflow integration

### Additional CLI Tools
- ast-grep, gdu, htop, xh, sd, glow, lynx
- xz, zstd, p7zip, unrar (compression)

### LLM CLI Tools (Optional)
- claude-code (Anthropic)
- gemini-cli (Google)
- grok-cli (xAI)

### Remote Access (Optional)
- Sunshine + Moonlight (low-latency game streaming)
- NoMachine (traditional remote desktop)
- Tailscale (secure mesh VPN + SSH)

## Ghostty Dropdown Terminal

DevEnv configures Ghostty's native quick terminal feature:

**Press F12** anywhere to toggle a dropdown terminal from the top of screen.

This replaces the need for Guake/Yakuake and uses Ghostty's built-in support for Wayland/Hyprland.

Configuration: `~/.config/ghostty/config`

## Shell Integration

DevEnv layers on top of Omarchy's shell configuration:

```bash
# Add to ~/.bashrc (after Omarchy's defaults)
source ~/.config/devenv/devenv-shell.sh
```

This sources tool configurations from `~/.shell.d/` without conflicting with Omarchy.

## Neovim Integration

DevEnv adds lazy-llm plugins to omarchy-nvim (doesn't replace it):

- `~/.config/nvim/lua/plugins/lazyllm-llm-send.lua`
- `~/.config/nvim/lua/plugins/lazyllm-git.lua`

## Remote-First Workstation Setup

For headless/remote operation (e.g., Beelink SER9):

```bash
./setup-omarchy.sh --all
```

This configures:

### Virtual Display (Headless)
```conf
# In ~/.config/hypr/hyprland.conf, add:
source = ~/.config/hypr/devenv-remote.conf
```

Creates a 2560x1440 virtual monitor that works without physical display.

### Auto-Login
- TTY1 auto-login (no password prompt)
- Hyprland auto-start on login
- Sunshine auto-start with graphical session

### Remote Access Stack

| Tool | Purpose | Port |
|------|---------|------|
| Sunshine | Game streaming server | 47989 |
| NoMachine | Traditional remote desktop | 4000 |
| Tailscale | Secure VPN + SSH | - |

### Recovery Path

If GUI fails:
1. SSH via Tailscale: `ssh user@hostname`
2. Switch TTY: `Ctrl+Alt+F2`

## Directory Structure

```
dotfiles/
├── ghostty/           # Dropdown terminal config
├── omarchy/           # Omarchy-specific configs
│   └── dot-config/
│       ├── devenv/    # Shell integration
│       ├── hypr/      # Hyprland overrides
│       └── systemd/   # User services
├── sunshine/          # Sunshine streaming config
└── [shared packages]  # Cross-platform configs

install-scripts/
├── install-autologin.sh      # Headless auto-login
├── install-lazyllm-omarchy.sh # lazy-llm for Omarchy
├── install-node-mise.sh       # Node via mise (not nvm)
├── install-nomachine.sh       # NoMachine backup
├── install-sunshine.sh        # Sunshine streaming
└── install-tailscale.sh       # Tailscale VPN
```

## Version Management

Omarchy uses **mise** (not pyenv/rbenv/nvm). DevEnv adapts to this:

```bash
# Node.js via mise
mise install node@20
mise use --global node@20

# Python via mise
mise install python@3.12
mise use --global python@3.12
```

## Troubleshooting

### Ghostty dropdown not working
- Ensure Ghostty 1.2+ is installed
- Check `~/.config/ghostty/config` has `keybind = global:f12=toggle_quick_terminal`

### Sunshine can't capture display
- Verify VAAPI: `vainfo`
- Check wlroots capture: Sunshine logs
- Ensure user is in `input`, `video`, `render` groups

### Headless boot fails
- Check getty override: `systemctl cat getty@tty1`
- Verify auto-start in `~/.bash_profile`
- Test SSH access as fallback

### tmux plugins not loading
- Run `prefix + I` inside tmux to install plugins
- Check TPM is initialized: `~/.config/tmux/plugins/tpm/`

## Updating

```bash
cd ~/dev-env
git pull
./setup-omarchy.sh  # Re-run to apply updates
```

Omarchy updates separately via `omarchy-update`.
