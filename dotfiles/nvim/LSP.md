# LSP Configuration Guide

This document describes the Language Server Protocol (LSP) setup for Neovim in this dev-env.

## Overview

LSP servers are automatically managed by **Mason** and configured via LazyVim. The configuration is located at:
- `dotfiles/nvim/.config/nvim/lua/plugins/lsp.lua`

## Supported Languages

### Currently Configured

| Language       | LSP Server                     | Formatter       | Linter        |
|----------------|--------------------------------|-----------------|---------------|
| Lua            | lua-language-server            | stylua          | -             |
| JavaScript/TS  | typescript-language-server     | prettier        | eslint_d      |
| Python         | pyright                        | black, isort    | pylint        |
| Terraform      | terraformls                    | terraform-fmt   | -             |
| Ansible        | ansible-language-server        | -               | ansible-lint  |
| HTML           | html-lsp                       | prettier        | -             |
| CSS            | css-lsp                        | prettier        | -             |
| JSON           | json-lsp                       | prettier        | -             |
| YAML           | yaml-language-server           | prettier        | yamllint      |
| Bash/Shell     | bash-language-server           | shfmt           | shellcheck    |
| C#             | omnisharp                      | -               | -             |
| C/C++          | clangd                         | -               | -             |
| Markdown       | marksman, markdown_oxide       | -               | -             |

## Installation

LSP servers are **automatically installed** when you first launch Neovim after running the install-nvim.sh script.

### Manual Installation

To manually install or update LSP servers:

1. Open Neovim: `nvim`
2. Open Mason: `:Mason`
3. Search for a package: Press `/` and type the package name
4. Install: Press `i` on the highlighted package
5. Update all: Press `U`

### Command-Line Installation

You can also install LSP servers from the command line:

```bash
nvim --headless "+MasonInstall typescript-language-server" +qa
nvim --headless "+MasonInstall pyright" +qa
```

## Usage

### Checking Active LSP Servers

`:LspInfo` - Shows active LSP servers for the current buffer

### Common LSP Keybindings (LazyVim Defaults)

| Keybinding | Action                          |
|------------|---------------------------------|
| `gd`       | Go to definition                |
| `gr`       | Go to references                |
| `K`        | Hover documentation             |
| `<leader>ca` | Code action                   |
| `<leader>rn` | Rename symbol                 |
| `[d`       | Previous diagnostic             |
| `]d`       | Next diagnostic                 |
| `<leader>f` | Format buffer                  |

### Diagnostics

LazyVim shows diagnostics inline and in the location list. To view all diagnostics:

`:Trouble` - Open diagnostics window (via trouble.nvim)

## Configuration

### Adding a New Language

To add LSP support for a new language:

1. **Find the LSP server name** in Mason registry:
   - Open Mason: `:Mason`
   - Search for your language
   - Note the exact package name

2. **Add to `lsp.lua`**:
   ```lua
   -- In dotfiles/nvim/.config/nvim/lua/plugins/lsp.lua

   -- Add to ensure_installed list:
   ensure_installed = {
     "your-language-server",
     -- ... existing servers
   }

   -- Add server configuration:
   servers = {
     your_server_name = {
       -- Optional: custom settings
       settings = {
         -- server-specific settings
       },
     },
   }
   ```

3. **Restart Neovim**: Mason will auto-install the new server

### Custom LSP Settings

Each LSP server can have custom settings. Examples:

```lua
-- TypeScript with inlay hints
tsserver = {
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayFunctionParameterTypeHints = true,
      },
    },
  },
},

-- Python with type checking
pyright = {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        autoSearchPaths = true,
      },
    },
  },
},

-- YAML with schema validation
yamlls = {
  settings = {
    yaml = {
      schemas = {
        kubernetes = "*.yaml",
        ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
      },
    },
  },
},
```

## Troubleshooting

### LSP Server Not Starting

1. Check if the server is installed:
   ```vim
   :Mason
   ```

2. Check for errors:
   ```vim
   :LspInfo
   :checkhealth mason
   ```

3. Check the LSP log:
   ```vim
   :LspLog
   ```
   Or view the file directly: `~/.local/state/nvim/lsp.log`

### Server Installed But Not Active

1. Verify the filetype is correct:
   ```vim
   :set filetype?
   ```

2. Check if the server is configured for this filetype:
   ```vim
   :LspInfo
   ```

3. Restart LSP:
   ```vim
   :LspRestart
   ```

### Formatting Not Working

1. Ensure formatter is installed:
   ```vim
   :Mason
   ```

2. Check conform.nvim configuration (formatters are handled by conform, not LSP directly)

3. Try manual format:
   ```vim
   :Format
   ```

## Performance Tips

1. **Disable unused servers**: Comment out servers you don't need in `lsp.lua`

2. **Limit large projects**: Some LSP servers struggle with large codebases
   - Use `.gitignore` to exclude `node_modules`, build directories, etc.
   - Configure workspace exclusions in server settings

3. **Use local LSP installation**: For better performance, install language-specific LSPs globally:
   ```bash
   # Python
   pip install pyright

   # JavaScript/TypeScript
   npm install -g typescript typescript-language-server
   ```

## Resources

- [Mason Registry](https://mason-registry.dev/registry/list) - All available packages
- [nvim-lspconfig Server Configurations](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md)
- [LazyVim LSP Documentation](https://www.lazyvim.org/plugins/lsp)
