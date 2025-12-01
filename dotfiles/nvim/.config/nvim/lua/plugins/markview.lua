-- Markview plugin for markdown rendering in-buffer
-- Alternative to glow.nvim with more extensive markdown support
-- Requires Neovim 0.10.3+ and tree-sitter parsers
-- Usage: Toggle with :Markview toggle or <leader>um

return {
  "OXY2DEV/markview.nvim",
  ft = { "markdown", "quarto", "rmd" }, -- Only load for markdown filetypes
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    -- Disable automatic attachment - use manual toggle instead
    preview = {
      enable = false, -- Start disabled, toggle with :Markview toggle
    },
  },
  keys = {
    { "<leader>um", "<cmd>Markview toggle<cr>", desc = "Toggle Markview" },
  },
}
