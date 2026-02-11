return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- Create a new list for parsers to keep
    local new_ensure_installed = {}
    -- Iterate over the existing list of parsers
    for _, parser in ipairs(opts.ensure_installed) do
      -- If the parser is not 'csharp', add it to the new list
      if parser ~= "csharp" then
        table.insert(new_ensure_installed, parser)
      end
    end
    -- Replace the old list with the new one
    opts.ensure_installed = new_ensure_installed
  end,
}
