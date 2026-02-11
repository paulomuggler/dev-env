return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = false,
    dependencies = {
      { "zbirenbaum/copilot.lua" },
      { "nvim-lua/plenary.nvim" },
    },
    build = "make tiktoken",
    opts = {
      model = "gpt-4.1",
      temperature = 0.1,
      window = {
        layout = "vertical",
        width = 0.5,
      },
      auto_insert_mode = true,
    },
    keys = {
      { "<leader>ac", "<cmd>CopilotChat<cr>", desc = "Copilot Chat" },
      { "<leader>aq", "<cmd>CopilotChatClose<cr>", desc = "Close Copilot Chat" },
      { "<leader>ar", "<cmd>CopilotChatReset<cr>", desc = "Reset Copilot Chat" },
      { "<leader>ae", "<cmd>CopilotChatExplain<cr>", desc = "Explain Code", mode = { "n", "v" } },
      { "<leader>at", "<cmd>CopilotChatTests<cr>", desc = "Generate Tests", mode = { "n", "v" } },
      { "<leader>af", "<cmd>CopilotChatFix<cr>", desc = "Fix Code", mode = { "n", "v" } },
      { "<leader>ao", "<cmd>CopilotChatOptimize<cr>", desc = "Optimize Code", mode = { "n", "v" } },
      { "<leader>ad", "<cmd>CopilotChatDocs<cr>", desc = "Generate Docs", mode = { "n", "v" } },
    },
  },
}
