-- vim-tmux-navigator: Seamless navigation between tmux panes and vim splits
return {
  "christoomey/vim-tmux-navigator",
  lazy = false, -- Load immediately for navigation to work properly
  keys = {
    -- Ctrl+hjkl navigation (primary - works everywhere)
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate Previous" },
  },
  init = function()
    -- Disable default plugin mappings, we'll set our own
    vim.g.tmux_navigator_no_mappings = 0
    vim.g.tmux_navigator_save_on_switch = 2
  end,
}
