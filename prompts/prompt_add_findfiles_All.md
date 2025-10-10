## “Find files including .gitignored”

Easiest reliable way (no Telescope) is to use **fd/rg** with a picker that lets you pass flags. I recommend **fzf-lua** (lightweight, fast). Add this and you’re done:

```lua
-- plugins/fzf-lua.lua
return {
  "ibhagwan/fzf-lua",
  cmd = "FzfLua",
  opts = {}, -- defaults are fine
  keys = {
    -- Normal files (respects .gitignore)
    { "<leader>ff", function() require("fzf-lua").files() end, desc = "Files" },

    -- ALL files: include hidden + gitignored
    { "<leader>fA", function()
        require("fzf-lua").files({
          fd_opts = "fd --type f --hidden --follow --no-ignore", -- show ignored
        })
      end,
      desc = "Files (ALL, incl. .gitignored)"
    },
  },
}
```

Now:

* `<leader>ff` → regular file finder
* `<leader>fA` → includes **hidden** and **gitignored** (`--no-ignore`)


Let's try out the above.
