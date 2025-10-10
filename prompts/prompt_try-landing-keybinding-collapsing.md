Short answer: yes, you can collapse `f/F` and `t/T` into one “smart” motion that asks **where to land** (on / before / after) after you type the target char. It’s not built-in; you need a tiny Lua mapping. Works fine, repeatable with `;`/`,` because it still uses native motions under the hood.

### What you’ll get

Sequence: `f` → `{char}` → `{landing}`
Landing keys:

* `.` or `<CR>` → **ON** the char
* `>` → **AFTER** the char (one col to the right)
* `<` → **BEFORE** the char (one col to the left)

Uppercase `F` does the same but searches **backward**.

### Drop-in Lua (LazyVim-friendly)

Put this in `lua/config/keymaps.lua` (or any loaded Lua file):

```lua
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

local function smart_find(backward)
  local ch = vim.fn.getcharstr()
  if ch == "" then return end

  -- ask landing: default "on" with <CR> or '.'
  local landing = vim.fn.getcharstr()
  local where
  if landing == ">" then
    where = "after"
  elseif landing == "<" then
    where = "before"
  elseif landing == "." or landing == "\r" or landing == "" then
    where = "on"
  else
    where = "on"
  end

  if not backward then
    if where == "on"    then feed("f" .. ch)
    elseif where == "after"  then feed("f" .. ch .. "l")
    else -- before
      feed("t" .. ch)
    end
  else
    if where == "on"    then feed("F" .. ch)
    elseif where == "after"  then feed("F" .. ch .. "l")
    else -- before
      feed("T" .. ch)
    end
  end
end

-- Map in normal / visual / operator-pending
vim.keymap.set({ "n", "x", "o" }, "f", function() smart_find(false) end, { desc = "Smart f: on/before/after" })
vim.keymap.set({ "n", "x", "o" }, "F", function() smart_find(true)  end, { desc = "Smart F: on/before/after (backward)" })
```

### Notes

* **Repeats**: `;` and `,` still work, because the final jump is just native `f/t/F/T` (+ optional `h/l`), so Vim’s repeat remembers it.
* **Flit/Leap**: this overrides `f/F`. If you use **flit.nvim**, either disable its `f/t` mappings or keep `t/T` as-is (your call). Leap (`s/S`) is unaffected.
* **macOS Alt**: unrelated here, but if you bind anything to `<A-…>`, remember Option-as-Meta settings.

That’s it. One key, one char, one landing choice. Fewer bindings, same power.

