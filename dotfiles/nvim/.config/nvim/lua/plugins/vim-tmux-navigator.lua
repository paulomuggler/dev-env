-- vim-tmux-navigator: Seamless navigation between tmux panes and vim splits
return {
  "christoomey/vim-tmux-navigator",
  lazy = false, -- Load immediately for navigation to work properly
  keys = {
    { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate Left" },
    { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate Down" },
    { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate Up" },
    { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate Right" },
    { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate Previous" },
  },
}
