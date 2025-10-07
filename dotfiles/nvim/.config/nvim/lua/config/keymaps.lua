-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- @ Path Completion for LLM Workspace References
-- @ opens fuzzy file picker (fast, see entire project tree)
-- The @ stays in the buffer so LLM parsers can recognize workspace links
vim.keymap.set("i", "@", function()
  -- Save the buffer and position before opening picker
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local row, col = unpack(vim.api.nvim_win_get_cursor(win))

  -- Insert @ character first and mark the position
  vim.api.nvim_buf_set_text(buf, row - 1, col, row - 1, col, { "@" })
  local at_col = col  -- Save the column where @ was inserted
  vim.api.nvim_win_set_cursor(win, { row, col + 1 })

  -- Get list of files using fd (fast file finder)
  vim.schedule(function()
    local cwd = vim.fn.getcwd()
    local fd_cmd = string.format("fd --type f . %s", vim.fn.shellescape(cwd))
    local files = vim.fn.systemlist(fd_cmd)

    -- Make paths relative to cwd
    for i, file in ipairs(files) do
      files[i] = vim.fn.fnamemodify(file, ":.")
    end

    -- Use vim.ui.select which will use Snacks.picker if configured
    vim.ui.select(files, {
      prompt = "@ Workspace File",
      format_item = function(item)
        return item
      end,
    }, function(selected)
      if selected then
        vim.schedule(function()
          -- Return to original window/buffer
          vim.api.nvim_set_current_win(win)
          vim.api.nvim_set_current_buf(buf)

          -- Insert the file path right after the @ (at_col + 1)
          vim.api.nvim_buf_set_text(buf, row - 1, at_col + 1, row - 1, at_col + 1, { selected })

          -- Move cursor to end of inserted text (after @ and path)
          vim.api.nvim_win_set_cursor(win, { row, at_col + 1 + #selected })
        end)
      end
    end)
  end)
end, { noremap = true, silent = true, desc = "@ fuzzy file picker for workspace references" })

-- <C-f> in insert mode triggers native vim file completion for drilling down paths
-- (Ctrl-/ doesn't work reliably in terminals, using Ctrl-f as alternative)
vim.keymap.set("i", "<C-f>", "<C-x><C-f>", { noremap = true, silent = true, desc = "Trigger native file completion" })
