# Fix: Support both string and table formats for safe_labels

## Issue

Flit.nvim breaks with leap.nvim commit [ce65ca3](https://github.com/ggandor/leap.nvim/commit/ce65ca3) and later versions with the error:

```
Error executing vim.schedule lua callback: ...l/share/nvim/lazy/flit.nvim/lua/flit.lua:174: bad argument #1 to 'ipairs' (table expected, got string)
```

This occurs when using `f`, `F`, `t`, or `T` motions.

## Root Cause

Leap.nvim commit ce65ca3 ("improv(api): deprecate support for label lists as tables") changed the `safe_labels` configuration from table format to string format:

**Before (table):**
```lua
safe_labels = {"s", "f", "n", "u", "t", "/", "S", "F", ...}
```

**After (string):**
```lua
safe_labels = "sfnut/SFNLHMUGTZ?"
```

Flit.nvim's `set_clever_repeat` function (line 174) uses `ipairs()` to iterate over `safe_labels`, which only works with tables, not strings.

## Solution

This PR adds type checking to handle both formats:

1. Check if `safe_labels` is a string or table
2. Convert string to table of characters if necessary before using `ipairs()`
3. Return the filtered result in the same format as the input
4. Maintain backward compatibility with older leap.nvim versions

## Changes

**File:** `lua/flit.lua` (lines 169-180)

### Before:
```lua
local safe_labels = require('leap').opts.safe_labels
if #safe_labels > 0 then
  local filtered_labels = {}
  for _, label in ipairs(safe_labels) do
    if label ~= (args.t and t or f) and label ~= (args.t and T or F) then
      table.insert(filtered_labels, label)
    end
  end
  cc_opts.safe_labels = filtered_labels
end
```

### After:
```lua
local safe_labels = require('leap').opts.safe_labels
if safe_labels and #safe_labels > 0 then
  local filtered_labels = {}

  -- Convert string to table if necessary (for leap.nvim ce65ca3+)
  local labels_table
  if type(safe_labels) == 'string' then
    -- Split string into table of single-character strings
    labels_table = {}
    for i = 1, #safe_labels do
      table.insert(labels_table, safe_labels:sub(i, i))
    end
  else
    -- Already a table (for older leap.nvim versions)
    labels_table = safe_labels
  end

  for _, label in ipairs(labels_table) do
    if label ~= (args.t and t or f) and label ~= (args.t and T or F) then
      table.insert(filtered_labels, label)
    end
  end

  -- Return filtered result in the same format as input
  if type(safe_labels) == 'string' then
    cc_opts.safe_labels = table.concat(filtered_labels)
  else
    cc_opts.safe_labels = filtered_labels
  end
end
```

## Testing

Tested with:
- ✅ leap.nvim @ a755cea (before breaking change) - table format
- ✅ leap.nvim @ ce65ca3+ (after breaking change) - string format
- ✅ All f/F/t/T motions work correctly
- ✅ Clever repeat functionality maintained
- ✅ Label filtering works in both formats

## Related Issues

Closes #54

## Compatibility

This change maintains full backward compatibility with older leap.nvim versions while adding support for the new string-based safe_labels format.
