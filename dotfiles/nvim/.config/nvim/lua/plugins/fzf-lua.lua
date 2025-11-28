-- fzf-lua: Fast fuzzy finder with fd/rg integration
-- Provides file finding with .gitignore control
--
-- Grep with glob filtering:
--   Use <leader>sg or <leader>sG for grep with ripgrep glob support
--   Syntax: pattern -- glob (double-dash separates pattern from glob)
--   Examples:
--     TODO -- *.lua        -> search TODO only in .lua files
--     function -- src/     -> search function only in src/
--     error -- !*.test.ts  -> search error, exclude test files
--     pcall -- *.lua !*spec*  -> search pcall in lua files, exclude spec

return {
  "ibhagwan/fzf-lua",
  opts = {
    winopts = {
      preview = { vertical = "down:50%" },
    },
    keymap = {
      fzf = {
        ["ctrl-p"] = "previous-history",
        ["ctrl-n"] = "next-history",
        ["ctrl-q"] = "select-all+accept", -- send all to quickfix
      },
    },
    -- Per-picker history
    files = {
      fzf_opts = {
        ["--history"] = vim.fn.stdpath("data") .. "/fzf-lua-files-history",
      },
    },
  },
  -- Override LazyVim's keymaps after plugin loads
  config = function(_, opts)
    local fzf = require("fzf-lua")
    fzf.setup(opts)

    -- Grep with glob support: use "pattern -- glob" syntax
    vim.keymap.set("n", "<leader>sg", function()
      fzf.live_grep_glob({
        fzf_opts = {
          ["--history"] = vim.fn.stdpath("data") .. "/fzf-lua-grep-history",
        },
      })
    end, { desc = "Grep (with glob)" })

    vim.keymap.set("n", "<leader>sG", function()
      fzf.live_grep_glob({
        search = vim.fn.expand("<cword>"),
        fzf_opts = {
          ["--history"] = vim.fn.stdpath("data") .. "/fzf-lua-grep-history",
        },
      })
    end, { desc = "Grep word (with glob)" })
  end,
  keys = {
    -- ALL files: include hidden + gitignored (but exclude noisy git internals)
    {
      "<leader>fA",
      function()
        -- Exclusions for noisy directories/files we don't want to see
        local exclusions = {
          ".git/objects",
          ".git/refs",
          ".git/logs",
          ".git/info",
          ".git/packed-refs",
          ".git/worktrees",
          ".git/modules",
          ".git/shallow",
          ".git/rr-cache",
          ".git/rebase-apply",
          ".git/rebase-merge",
          ".git/ORIG_HEAD",
          ".git/INDEX.lock",
          ".git/FETCH_HEAD",
          -- Add more exclusions here as needed
        }

        -- Build fd command with exclusions
        local fd_cmd = { " --type f --hidden --follow --no-ignore" }
        for _, excl in ipairs(exclusions) do
          table.insert(fd_cmd, "--exclude " .. excl)
        end

        require("fzf-lua").files({
          fd_opts = table.concat(fd_cmd, " "),
        })
      end,
      desc = "Files (ALL, incl. .gitignored)",
    },
  },
}
