-- Plugin to prompt before reloading file when it changes on disk
return {
  {
    "folke/noice.nvim",
    optional = true,
    opts = function(_, opts)
      -- Configure autocmd to handle file changes
      vim.api.nvim_create_autocmd("FileChangedShell", {
        group = vim.api.nvim_create_augroup("file_changed_prompt", { clear = true }),
        callback = function()
          vim.schedule(function()
            vim.ui.select(
              { "Reload", "Keep current version" },
              {
                prompt = "File changed on disk",
                format_item = function(item)
                  return item
                end,
              },
              function(choice)
                if choice == "Reload" then
                  vim.cmd("edit!")
                  vim.notify("File reloaded from disk", vim.log.levels.INFO)
                elseif choice then
                  vim.notify("Keeping current version", vim.log.levels.WARN)
                end
              end
            )
          end)
        end,
      })

      return opts
    end,
  },
}
