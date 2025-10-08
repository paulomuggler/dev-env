# Neovim Configuration Package

This package manages `neovim` (LazyVim) configuration and shell integration.

## Files

- `nvim.sh` → Symlinked to `shell.d/nvim.sh` - Shell functions and aliases
- `.config/nvim/` → `~/.config/nvim/` - LazyVim configuration (stowed)

## Shell Integration

The `nvim.sh` file provides:

### Functions
- `nvim_plain()` - Plain Neovim without any configuration
  - Uses `NVIM_APPNAME=nvim-plain` if `~/.config/nvim-plain` exists
  - Otherwise uses `nvim --clean` for completely clean start
- `lazyvim_func()` - Backward compatibility function (just calls nvim)

### Aliases
- `lazyvim` → `nvim` - LazyVim is the default
- `nvim-plain` → `nvim_plain` - Quick access to clean nvim

## Configuration

The current setup uses **LazyVim** as the default Neovim configuration at `~/.config/nvim/`.

### Python Provider
Neovim uses a Python virtual environment for Python integration:
- Location: `~/.venvs/nvim/bin/python3`
- Configured in: `lua/config/options.lua`

### Custom Plugins
The configuration includes custom plugins symlinked from the lazy-llm submodule:
- `lua/plugins/git.lua` → `external/lazy-llm/nvim/.config/nvim/lua/plugins/git.lua`
- `lua/plugins/llm-send.lua` → `external/lazy-llm/nvim/.config/nvim/lua/plugins/llm-send.lua`

The lazy-llm project is included as a git submodule at `external/lazy-llm/`. This ensures the plugins remain accessible and the symlinks don't break when moving the config.

**Updating submodule:**
```bash
cd ~/Projects/dev-env
git submodule update --remote external/lazy-llm
```

### LLM Workspace Integration

See the **lazy-llm** submodule for LLM-specific features:
- `lua/plugins/llm-send.lua` (symlinked) - Send buffers to LLM CLI
- `lua/plugins/git.lua` (symlinked) - Git integration for LLM workflows

#### @ Path Completion (from lazy-llm)
The llm-send plugin provides path completion for workspace file references:

**Method 1: Fuzzy Finder (Primary)**
- Type `@` in insert mode → fuzzy picker opens
- Search: `comp butt tsx` → finds `src/components/Button.tsx`
- Result: `@src/components/Button.tsx`

**Method 2: Native File Completion (Alternative)**
- Press `<Ctrl-f>` in insert mode → native vim completion
- Drill down: `src/<Ctrl-f> components/<Ctrl-f> Button.tsx`

**Implementation:** See `external/lazy-llm/nvim-llm-send-plugin/.config/nvim/lua/plugins/llm-send.lua:92-157`

## Dependencies

Neovim requires several language providers and tools:

### Core Dependencies
- **Neovim** >= 0.9.0 (via Homebrew)
- **Git** >= 2.19.0
- **Nerd Font** (FiraCode Nerd Font recommended)

### Language Providers
- **Python**: Virtual environment at `~/.venvs/nvim/` with `pynvim`
- **Node.js**: npm package `neovim`
- **Ruby**: rbenv-managed Ruby with `neovim` gem
- **Perl**: `Neovim::Ext` via cpanm

### Optional LazyVim Dependencies
These enhance LazyVim functionality but are not strictly required:
- **Languages**: fish, go, rust, php, java (openjdk), julia
- **Build tools**: ast-grep, luarocks, composer
- **Documentation**: ghostscript, tectonic, mermaid-cli
- **Utilities**: fd, gdu, bottom

## Installation

The install script handles:
1. Installing Neovim via Homebrew
2. Checking/installing dependencies
3. Setting up Python virtual environment
4. Installing language providers
5. Stowing configuration
6. Linking shell integration

## Customization

Edit files in `dotfiles/nvim/.config/nvim/` to customize:
- `lua/config/options.lua` - Neovim options
- `lua/config/keymaps.lua` - Custom keymaps
- `lua/config/autocmds.lua` - Autocommands
- `lua/plugins/` - Plugin configurations

Changes are automatically reflected as the directory is stowed.

## Notes

- LazyVim manages its own plugins via lazy.nvim
- First launch will install all plugins automatically
- Run `:checkhealth` in Neovim to verify all providers work
- Plugin updates: `:Lazy sync`
- LSP management: `:Mason`
