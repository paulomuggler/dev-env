-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Quickfix: use dd to remove item from quickfix list
local function remove_qf_item()
  local curqfidx = vim.fn.line(".") - 1
  local qfall = vim.fn.getqflist()
  table.remove(qfall, curqfidx + 1) -- Lua tables are 1-indexed
  vim.fn.setqflist(qfall, "r")
  if #qfall > 0 then
    vim.cmd(string.format("%dcfirst", math.min(curqfidx + 1, #qfall)))
    vim.cmd("copen")
  else
    vim.cmd("cclose")
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf",
  callback = function()
    vim.keymap.set("n", "dd", remove_qf_item, { buffer = true, desc = "Remove quickfix item" })
  end,
})
