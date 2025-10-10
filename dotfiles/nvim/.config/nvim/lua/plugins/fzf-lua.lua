-- fzf-lua: Fast fuzzy finder with fd/rg integration
-- Provides file finding with .gitignore control

return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  opts = {}, -- defaults are fine
  keys = {
    -- Normal files (respects .gitignore)
    -- {
    --   "<leader>ff",
    --   function()
    --     require("fzf-lua").files()
    --   end,
    --   desc = "Files",
    -- },

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
