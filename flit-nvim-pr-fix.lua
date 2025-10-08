-- PR Fix for flit.nvim to support both string and table safe_labels
-- This fixes compatibility with leap.nvim commit ce65ca3 and later
-- which changed safe_labels from table to string format

-- Original code (lines 169-180):
--[[
local safe_labels = require('leap').opts.safe_labels
if #safe_labels > 0 then
  local filtered_labels = {}
  -- Note: this is executed on `LeapEnter`, so the label lists
  -- have already been converted to tables.
  for _, label in ipairs(safe_labels) do
    if label ~= (args.t and t or f) and label ~= (args.t and T or F) then
      table.insert(filtered_labels, label)
    end
  end
  cc_opts.safe_labels = filtered_labels
end
]]

-- Fixed code (replace lines 169-180):
local safe_labels = require("leap").opts.safe_labels
if safe_labels and #safe_labels > 0 then
	local filtered_labels = {}

	-- Convert string to table if necessary (for leap.nvim ce65ca3+)
	local labels_table
	if type(safe_labels) == "string" then
		-- Split string into table of single-character strings
		labels_table = {}
		for i = 1, #safe_labels do
			table.insert(labels_table, safe_labels:sub(i, i))
		end
	else
		-- Already a table (for older leap.nvim versions)
		labels_table = safe_labels
	end

	-- Note: this is executed on `LeapEnter`, so the label lists
	-- have already been converted to tables.
	for _, label in ipairs(labels_table) do
		if label ~= (args.t and t or f) and label ~= (args.t and T or F) then
			table.insert(filtered_labels, label)
		end
	end

	-- Return filtered result in the same format as input
	if type(safe_labels) == "string" then
		cc_opts.safe_labels = table.concat(filtered_labels)
	else
		cc_opts.safe_labels = filtered_labels
	end
end

--[[
Summary of Changes:
1. Added type check to determine if safe_labels is a string or table
2. Convert string to table of characters before using ipairs()
3. Return filtered result in same format as input (string or table)
4. Maintains backward compatibility with older leap.nvim versions

This fix allows flit.nvim to work with both:
- Old leap.nvim: safe_labels = {"s", "f", "n", ...}  (table)
- New leap.nvim: safe_labels = "sfnut/SFNLHMUGTZ?"   (string)

Files to change in flit.nvim:
- lua/flit.lua: lines 169-180

GitHub Issue Reference:
- https://github.com/ggandor/flit.nvim/issues/55
]]
