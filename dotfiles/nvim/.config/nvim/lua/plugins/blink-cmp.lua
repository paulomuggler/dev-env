-- blink.cmp configuration
-- Replaces default path provider with custom one that supports @ workspace completion

return {
	{
		"saghen/blink.cmp",
		opts = function(_, opts)
			-- Ensure sources table exists
			opts.sources = opts.sources or {}
			opts.sources.default = opts.sources.default or {}
			opts.sources.providers = opts.sources.providers or {}

			-- Replace path provider with our custom workspace-aware version
			opts.sources.providers.path = {
				name = "Path",
				module = "blink-cmp-path-workspace", -- Our custom module
				score_offset = 3,
				opts = {
					-- Options are set in the custom module with smart defaults
					-- @ paths: workspace root + hidden files
					-- / ./ ~/ paths: relative to current file + hidden files
					-- All: trailing slashes preserved for directories
				},
			}

			return opts
		end,
	},
}
