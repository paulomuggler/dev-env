-- emoji.nvim - Emoji completion source for Blink
return {
	"Allaman/emoji.nvim",
	dependencies = { "saghen/blink.cmp" },
	opts = {},
	config = function()
		require("emoji").setup({})

		-- Integrate with blink.cmp
		local blink = require("blink.cmp")
		local current_config = blink.config or {}
		local sources = current_config.sources or {}
		local default_sources = sources.default or { "lsp", "path", "snippets", "buffer" }

		-- Add emoji to sources if not already present
		if not vim.tbl_contains(default_sources, "emoji") then
			table.insert(default_sources, "emoji")
		end

		sources.default = default_sources
		current_config.sources = sources

		blink.setup(current_config)
	end,
}
