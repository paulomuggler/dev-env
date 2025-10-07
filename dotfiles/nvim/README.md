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

#### @ Path Completion (Fuzzy Finder + Native)
Two completion methods for referencing workspace files in LLM prompts:

**Method 1: Fuzzy Finder (Primary - Fast & Convenient)**
1. Type `@` in insert mode
2. Fuzzy file picker opens (Snacks.picker)
3. Type fragments: `comp butt tsx` → finds `src/components/Button.tsx`
4. Select file → inserts: `@src/components/Button.tsx`

**Method 2: Native File Completion (Alternative - Traditional)**
1. Press `<Ctrl-f>` in insert mode (or after typing partial path)
2. Native vim file completion menu appears (`<C-x><C-f>`)
3. Navigate through directories level by level
4. Useful for drilling down known paths: `src/<Ctrl-f> components/<Ctrl-f> Button.tsx`

**Example:**
```
Please refactor @src/components/Button.tsx to use composition.
Also update @tests/Button.test.tsx accordingly.
```

**How it works:**
- `@` → Opens fuzzy picker showing all project files (configured in `lua/config/keymaps.lua:8`)
- `<C-f>` → Triggers vim's native path completion (Ctrl-/ doesn't work in terminals)
- The `@` stays in the buffer for LLM parsers to recognize workspace links
- Paths are relative to nvim's current working directory

**Tip:** For git-root-relative paths, set your nvim cwd to the repository root using `:cd` or a rooter plugin.

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
