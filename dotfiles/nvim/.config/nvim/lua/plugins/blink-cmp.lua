-- blink.cmp configuration
-- Show hidden files in native path completion (/, ./, ~/)

return {
	{
		"saghen/blink.cmp",
		opts = function(_, opts)
			opts.sources = opts.sources or {}
			opts.sources.providers = opts.sources.providers or {}

			-- Show hidden files in path completion
			if not opts.sources.providers.path then
				opts.sources.providers.path = {}
			end
			opts.sources.providers.path.opts = opts.sources.providers.path.opts or {}
			opts.sources.providers.path.opts.show_hidden_files_by_default = true

			return opts
		end,
	},
}
