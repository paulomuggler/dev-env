-- LSP Configuration for multiple languages
-- Configures mason.nvim and mason-lspconfig.nvim to auto-install and setup LSP servers

return {
  -- Mason: LSP server installer
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Language Servers
        "lua-language-server", -- Lua
        "typescript-language-server", -- JavaScript/TypeScript
        "pyright", -- Python
        "terraform-ls", -- Terraform
        "ansible-language-server", -- Ansible
        "html-lsp", -- HTML
        "css-lsp", -- CSS
        "json-lsp", -- JSON
        "yaml-language-server", -- YAML
        "bash-language-server", -- Bash
        "omnisharp", -- C#
        "clangd", -- C/C++
        "marksman", -- Markdown (alternative to markdown_oxide)

        -- Formatters
        "prettier", -- Multi-language formatter (JS/TS/HTML/CSS/JSON)
        "stylua", -- Lua formatter
        "black", -- Python formatter
        "isort", -- Python import sorter
        "shfmt", -- Shell script formatter
        -- Note: Terraform formatting is built into terraform-ls, no separate formatter needed

        -- Linters
        "eslint_d", -- JavaScript/TypeScript linter
        "pylint", -- Python linter
        "shellcheck", -- Shell script linter
        "yamllint", -- YAML linter
        "ansible-lint", -- Ansible linter
      },
    },
  },

  -- Mason-lspconfig: Bridge between mason and lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Auto-configure LSP servers installed by Mason
      servers = {
        -- Lua
        lua_ls = {},

        -- JavaScript/TypeScript
        tsserver = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },

        -- Python
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
              },
            },
          },
        },

        -- Terraform
        terraformls = {}, -- Note: package is terraform-ls, but lspconfig uses terraformls

        -- Ansible
        ansiblels = {},

        -- HTML
        html = {
          filetypes = { "html", "htmldjango" },
        },

        -- CSS
        cssls = {},

        -- JSON
        jsonls = {},

        -- YAML
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                kubernetes = "*.yaml",
                ["http://json.schemastore.org/github-workflow"] = ".github/workflows/*",
                ["http://json.schemastore.org/github-action"] = ".github/action.{yml,yaml}",
                ["http://json.schemastore.org/ansible-stable-2.9"] = "roles/tasks/*.{yml,yaml}",
                ["http://json.schemastore.org/prettierrc"] = ".prettierrc.{yml,yaml}",
                ["http://json.schemastore.org/kustomization"] = "kustomization.{yml,yaml}",
                ["http://json.schemastore.org/ansible-playbook"] = "*play*.{yml,yaml}",
              },
            },
          },
        },

        -- Bash
        bashls = {},

        -- C#
        omnisharp = {},

        -- C/C++
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
        },

        -- Markdown
        marksman = {},
      },
    },
  },
}
