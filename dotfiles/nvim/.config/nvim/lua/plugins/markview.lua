-- Markview plugin for markdown rendering in-buffer
-- Alternative to glow.nvim with more extensive markdown support
-- Requires Neovim 0.10.3+ and tree-sitter parsers
-- Usage: Automatically renders markdown files with enhanced preview

return {
  "OXY2DEV/markview.nvim",
  lazy = false, -- Plugin is already internally lazy-loaded
  dependencies = {
    -- Icon support (LazyVim already has mini.icons)
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("markview").setup({
      -- Use default configuration
      -- Automatically renders when opening markdown files
    })
  end,
}
