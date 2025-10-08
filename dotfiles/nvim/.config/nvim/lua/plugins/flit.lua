-- leap.nvim pin to fix flit.nvim ipairs error
-- Breaking change: ce65ca3 "improv(api): deprecate support for label lists as tables"
-- Changed safe_labels from table to string, but flit.nvim still expects table
-- See: https://github.com/ggandor/flit.nvim/issues/54

return {
  {
    "ggandor/leap.nvim",
    -- Pin to last commit before ce65ca3 broke flit compatibility
    commit = "a755cea5ec06191b46702ac8fde8ef03ad2fbdeb",
  },
}
