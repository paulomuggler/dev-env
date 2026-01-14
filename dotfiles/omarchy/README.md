# Omarchy Configuration Package

DevEnv integration for Omarchy (Arch Linux + Hyprland).

## Contents

### Shell Integration
- `~/.config/devenv/devenv-shell.sh` - Sources `~/.shell.d/*.sh` for tool configs

### Hyprland Configuration
- `~/.config/hypr/devenv-remote.conf` - Virtual display + remote optimizations

### Systemd Services
- `~/.config/systemd/user/sunshine.service` - Sunshine auto-start

## Installation

This package is installed by `setup-omarchy.sh` via stow:

```bash
cd ~/dev-env/dotfiles
stow --dotfiles -t ~ omarchy
```

## Shell Integration

Add to your `~/.bashrc` (after Omarchy's default sourcing):

```bash
source ~/.config/devenv/devenv-shell.sh
```

## Hyprland Integration

Add to your `~/.config/hypr/hyprland.conf`:

```conf
source = ~/.config/hypr/devenv-remote.conf
```

## Files

```
dot-config/
├── devenv/
│   └── devenv-shell.sh    → ~/.config/devenv/devenv-shell.sh
├── hypr/
│   └── devenv-remote.conf → ~/.config/hypr/devenv-remote.conf
└── systemd/
    └── user/
        └── sunshine.service → ~/.config/systemd/user/sunshine.service
```
