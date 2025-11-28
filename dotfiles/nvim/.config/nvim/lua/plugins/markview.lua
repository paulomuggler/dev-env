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
      preview = {
        -- Only attach to buffers with valid markdown-like filetypes
        filetypes = { "markdown", "quarto", "rmd", "typst" },
        -- Skip buffers without valid parser or floating windows
        condition = function(buf)
          local ft = vim.bo[buf].filetype
          -- Skip if no filetype
          if not ft or ft == "" then
            return false
          end
          -- Skip if treesitter doesn't have a parser for this filetype
          local ok, _ = pcall(vim.treesitter.get_parser, buf)
          if not ok then
            return false
          end
          -- Skip floating windows and special buffers
          local win = vim.fn.bufwinid(buf)
          if win ~= -1 then
            local win_config = vim.api.nvim_win_get_config(win)
            if win_config.relative ~= "" then
              return false -- floating window
            end
          end
          -- Skip scratch/nofile buffers
          if vim.bo[buf].buftype ~= "" then
            return false
          end
          return true
        end,
      },
    })
  end,
}
