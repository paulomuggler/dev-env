-- Custom blink.cmp source for @ workspace path completion
-- Extends the built-in path source to add @ as a trigger and use workspace root

local path_source = require('blink.cmp.sources.path')
local lib = require('blink.cmp.sources.path.lib')

--- @class blink.cmp.Source
local workspace_path = {}

function workspace_path.new(opts)
	local self = setmetatable({}, { __index = workspace_path })

	-- Options with workspace-specific defaults
	opts = vim.tbl_deep_extend('keep', opts or {}, {
		trailing_slash = true,
		label_trailing_slash = true,
		show_hidden_files_by_default = true,
		get_cwd = function(context)
			return vim.fn.expand(('#%d:p:h'):format(context.bufnr))
		end,
	})

	self.opts = opts
	return self
end

-- Add @ as a trigger character
function workspace_path:get_trigger_characters()
	return { '/', '.', '\\', '@' }
end

-- Custom dirname detection that handles @ prefix
local function get_dirname_for_at(opts, context)
	local line_before_cursor = context.line:sub(1, context.cursor[2])

	-- Match @ that is either:
	-- 1. At start of line: ^@
	-- 2. Preceded by whitespace: %s@
	-- Followed by non-whitespace path: ([^%s]*)
	local at_match = line_before_cursor:match('^@([^%s]*)$')
		or line_before_cursor:match('%s@([^%s]*)$')

	if not at_match then
		return nil, nil
	end

	-- We're in @ context
	local git_root = vim.fn.systemlist('git rev-parse --show-toplevel 2>/dev/null')[1]
	local workspace_root = (git_root and git_root ~= '' and vim.v.shell_error == 0) and git_root or vim.fn.getcwd()

	-- Parse the path after @: remove incomplete part after last /
	local path_part = at_match:gsub('[^/]*$', '')

	-- Clean up path_part (remove leading/trailing slashes)
	if path_part == '' then
		-- Just @, no path yet -> use workspace root
		return workspace_root, at_match
	else
		-- @some/path/ -> workspace_root/some/path
		path_part = path_part:gsub('^/', ''):gsub('/$', '')
		return vim.fn.resolve(workspace_root .. '/' .. path_part), at_match
	end
end

-- Get custom text edit ranges that preserve @
local function get_at_text_edit_ranges(context, at_path)
	local line_before_cursor = context.line:sub(1, context.cursor[2])
	local at_start = line_before_cursor:find('@[^%s]*$')

	-- Find start of the last path component (after last /)
	local last_slash = at_path:reverse():find('/')
	local start_col
	if last_slash then
		start_col = context.cursor[2] - (last_slash - 1)
	else
		-- No slash in path, start right after @
		start_col = at_start
	end

	-- Check if there's already a trailing slash after cursor
	local next_char = context.line:sub(context.cursor[2] + 1, context.cursor[2] + 1)
	local has_trailing_slash = next_char == '/'

	return {
		file = {
			start = { line = context.cursor[1] - 1, character = start_col },
			['end'] = { line = context.cursor[1] - 1, character = context.cursor[2] },
		},
		directory = {
			start = { line = context.cursor[1] - 1, character = start_col },
			-- If there's already a slash after cursor, replace it to avoid double slash
			['end'] = { line = context.cursor[1] - 1, character = context.cursor[2] + (has_trailing_slash and 1 or 0) },
		},
	}
end

-- Get candidates with custom text edit ranges for @
local function get_at_candidates(context, dirname, include_hidden, opts, at_path)
	local fs = require('blink.cmp.sources.path.fs')
	local ranges = get_at_text_edit_ranges(context, at_path)

	return fs.scan_dir_async(dirname):map(function(entries)
		return fs.fs_stat_all(dirname, entries)
	end):map(function(entries)
		return vim.tbl_filter(function(entry)
			return include_hidden or entry.name:sub(1, 1) ~= '.'
		end, entries)
	end):map(function(entries)
		return vim.tbl_map(function(entry)
			local is_dir = entry.type == 'directory'
			local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
			local insert_text = is_dir and opts.trailing_slash and entry.name .. '/' or entry.name

			return {
				label = (opts.label_trailing_slash and is_dir) and entry.name .. '/' or entry.name,
				kind = is_dir and CompletionItemKind.Folder or CompletionItemKind.File,
				insertText = insert_text,
				textEdit = {
					newText = insert_text,
					range = is_dir and ranges.directory or ranges.file,
				},
				sortText = (is_dir and '1' or '2') .. entry.name:lower(),
				data = { path = entry.name, full_path = dirname .. '/' .. entry.name, type = entry.type, stat = entry.stat },
			}
		end, entries)
	end)
end

-- Get recursive candidates for fuzzy search (when user is typing)
local function get_recursive_candidates(context, dirname, include_hidden, opts, at_path)
	local async = require('blink.cmp.lib.async')
	local ranges = get_at_text_edit_ranges(context, at_path)

	return async.task.new(function(resolve, reject)
		-- Limit recursive search with max-results to avoid overwhelming the picker
		-- Also exclude common noise directories
		local cmd = string.format(
			'fd --hidden --exclude .git --exclude node_modules --exclude .cache --max-results 500 --base-directory %s --type f --type d',
			vim.fn.shellescape(dirname)
		)

		vim.fn.jobstart(cmd, {
			stdout_buffered = true,
			on_stdout = function(_, data)
				if not data then
					return resolve({})
				end

				local items = {}
				for _, path in ipairs(data) do
					if path and path ~= '' then
						-- Filter hidden files if needed
						if include_hidden or (not path:match('^%.') and not path:match('/%.')) then
							local full_path = dirname .. '/' .. path
							local is_dir = vim.fn.isdirectory(full_path) == 1
							local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
							local insert_text = is_dir and opts.trailing_slash and path .. '/' or path

							table.insert(items, {
								label = (opts.label_trailing_slash and is_dir) and path .. '/' or path,
								kind = is_dir and CompletionItemKind.Folder or CompletionItemKind.File,
								insertText = insert_text,
								textEdit = { newText = insert_text, range = is_dir and ranges.directory or ranges.file },
								sortText = (is_dir and '1' or '2') .. path:lower(),
								data = { path = path, full_path = full_path, type = is_dir and 'directory' or 'file' },
							})
						end
					end
				end
				resolve(items)
			end,
			on_stderr = function()
				reject()
			end,
		})
	end)
end

function workspace_path:get_completions(context, callback)
	callback = vim.schedule_wrap(callback)

	-- Try @ path first
	local dirname, at_path = get_dirname_for_at(self.opts, context)
	local is_at_context = dirname ~= nil

	-- If not @ path, use default path detection
	if not dirname then
		dirname = lib.dirname(self.opts, context)
	end

	if not dirname then
		return callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
	end

	local include_hidden = self.opts.show_hidden_files_by_default
		or (string.sub(context.line, context.bounds.start_col, context.bounds.start_col) == '.' and context.bounds.length == 0)
		or (
			string.sub(context.line, context.bounds.start_col - 1, context.bounds.start_col - 1) == '.'
			and context.bounds.length > 0
		)

	-- Determine if user is typing (fuzzy mode) or just browsing (sequential mode)
	-- Extract just the path part after @ (excluding the @ itself)
	local is_typing = false
	if is_at_context and at_path then
		-- Get the part after the last / in the @ path
		local after_last_slash = at_path:match('[^/]*$')
		-- If there's text after last slash (and it's not empty), user is typing
		is_typing = after_last_slash and #after_last_slash > 0

		-- DEBUG: Log the mode detection
		vim.notify(
			string.format('@ path: "%s", after_slash: "%s", typing: %s', at_path, after_last_slash or 'nil', is_typing),
			vim.log.levels.INFO
		)
	end

	local candidates_promise
	if is_at_context and is_typing then
		-- Fuzzy mode: show all files recursively
		vim.notify('Using FUZZY mode', vim.log.levels.WARN)
		candidates_promise = get_recursive_candidates(context, dirname, include_hidden, self.opts, at_path)
	elseif is_at_context then
		-- Sequential mode: show current directory only
		vim.notify('Using SEQUENTIAL mode', vim.log.levels.WARN)
		candidates_promise = get_at_candidates(context, dirname, include_hidden, self.opts, at_path)
	else
		-- Standard path completion
		candidates_promise = lib.candidates(context, dirname, include_hidden, self.opts)
	end

	candidates_promise
		:map(function(candidates)
			callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = candidates })
		end)
		:catch(function()
			callback()
		end)
end

function workspace_path:resolve(item, callback)
	require('blink.cmp.sources.path.fs')
		.read_file(item.data.full_path, 1024)
		:map(function(content)
			local is_binary = content:find('\0')
			if is_binary then
				item.documentation = { kind = 'plaintext', value = 'Binary file' }
			else
				local ext = vim.fn.fnamemodify(item.data.path, ':e')
				item.documentation = { kind = 'markdown', value = '```' .. ext .. '\n' .. content .. '```' }
			end
			return item
		end)
		:map(function(resolved_item)
			callback(resolved_item)
		end)
		:catch(function()
			callback(item)
		end)
end

return workspace_path
