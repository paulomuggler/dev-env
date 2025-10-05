# File Changed Plugin

## Overview

This plugin prompts the user when a file has been modified on disk outside of Neovim, offering the choice to reload the file or keep the current buffer version.

## How It Works

### FileChangedShell Autocmd

The plugin uses Neovim's `FileChangedShell` autocmd event, which triggers when:
- A file is changed outside of Neovim while the buffer is open
- Neovim regains focus and detects the file modification
- The file is modified by another process (git checkout, external editor, build tool, etc.)

### User Interaction

When a file change is detected, the plugin:

1. **Shows a selection prompt** with two options:
   - `Reload` - Discard buffer changes and reload from disk
   - `Keep current version` - Keep the current buffer contents

2. **Executes the choice**:
   - **Reload**: Runs `:edit!` to force reload from disk
   - **Keep**: Maintains current buffer (file remains modified)

3. **Provides feedback** via `vim.notify()` to confirm the action taken

## Implementation Details

### vim.schedule()
```lua
vim.schedule(function()
  -- UI operations here
end)
```
Wraps the UI prompt in `vim.schedule()` to defer execution, preventing issues with autocmd context restrictions.

### vim.ui.select()
```lua
vim.ui.select(items, opts, on_choice)
```
Native Neovim selection UI that:
- Works standalone with basic terminal UI
- Enhanced by Noice.nvim when available (better styling, positioning)
- Falls back gracefully if Noice is not installed

**Parameters:**
- `items`: List of choices (`{ "Reload", "Keep current version" }`)
- `opts.prompt`: Title shown to user
- `opts.format_item`: Function to format each item (identity function in our case)
- `on_choice`: Callback receiving user's selection

### vim.cmd("edit!")
```lua
vim.cmd("edit!")
```
The `edit!` command:
- Forces reload of current file from disk
- Discards any unsaved changes in buffer
- Updates buffer with disk contents
- Maintains cursor position when possible

## Customization

### Change Prompt Options

Edit the items array to customize choices:
```lua
vim.ui.select(
  { "Yes, reload", "No, keep mine" },  -- Custom text
  -- ...
)
```

### Auto-reload Without Prompt

To skip the prompt and always reload:
```lua
vim.api.nvim_create_autocmd("FileChangedShell", {
  callback = function()
    vim.cmd("edit!")
    vim.notify("File auto-reloaded from disk", vim.log.levels.INFO)
  end,
})
```

### Auto-keep Without Prompt

To skip the prompt and always keep current version:
```lua
vim.api.nvim_create_autocmd("FileChangedShell", {
  callback = function()
    vim.notify("File changed on disk (kept current version)", vim.log.levels.WARN)
  end,
})
```

### Add File Type Filters

To only prompt for specific file types:
```lua
vim.api.nvim_create_autocmd("FileChangedShell", {
  pattern = "*.lua,*.md",  -- Only for Lua and Markdown files
  callback = function()
    -- ...
  end,
})
```

### Change Notification Levels

Customize the log levels for notifications:
```lua
-- On reload
vim.notify("File reloaded", vim.log.levels.INFO)   -- Current: INFO
vim.notify("File reloaded", vim.log.levels.WARN)   -- Could use WARN

-- On keep
vim.notify("Kept current", vim.log.levels.WARN)    -- Current: WARN
vim.notify("Kept current", vim.log.levels.ERROR)   -- Could use ERROR
```

## Dependencies

- **Optional**: `folke/noice.nvim` - Enhanced UI for notifications and prompts
- **Fallback**: Works with vanilla Neovim if Noice not installed

## Common Scenarios

### Git Branch Switching
When switching git branches, files often change on disk. This plugin prompts for each affected open buffer.

### Build Tool Output
When build tools regenerate source files, the plugin catches the changes.

### External Editor
When the same file is edited in another editor or IDE while open in Neovim.

## Limitations

- Only triggers when Neovim detects the change (usually on focus gain or buffer interaction)
- Does not prevent conflicts - just provides awareness and choice
- Choosing "Keep" means your buffer is now out of sync with disk (will prompt to overwrite on save)

## See Also

- `:help FileChangedShell` - Vim documentation for the autocmd event
- `:help vim.ui.select()` - Neovim UI selection function
- `:help edit` - Neovim edit command documentation
