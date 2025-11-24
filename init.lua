-- Copyright 2014-2025 Mitchell. See LICENSE.

--- A Textadept module for loading an interactive Lua REPL using the editor's Lua State, similar
-- to Lua's interactive REPL.
-- This is an alternative to the single-line Lua command entry.
--
-- Install this module by copying it into your *~/.textadept/modules/* directory or Textadept's
-- *modules/* directory, and then putting the following in your *~/.textadept/init.lua*:
--
-- ```lua
-- local lua_repl = require('lua_repl')
-- ```
--
-- Select "Tools > Lua REPL" to open the REPL. Typing the Enter key on any line evaluates that
-- line, unless that line is a continuation line. In that case, when finished, select the lines
-- to evaluate and type Enter to evaluate the entire chunk.
--
-- Tab completion is available, as is cycling through history with the `Ctrl+Up`/`Ctrl+Down`
-- and `Ctrl+P` and `Ctrl+N` keys.
--
-- **Note:** if the Language Server Protocol (LSP) module is enabled, any completions coming
-- from that module are separate from this module's completions.
--
-- Lines may be optionally prefixed with '=' (similar to the Lua prompt) to print a result.
-- @module lua_repl
local M = {}

--- A special environment for a Lua REPL.
-- It has an `__index` metafield for accessing Textadept's global environment.
-- @table env
-- @local
local env = setmetatable({
	print = function(...args)
		buffer:add_text('--> ')
		for i = 1, args.n do
			buffer:add_text(tostring(args[i]))
			if i < args.n then buffer:add_text('\t') end
		end
		buffer:new_line()
	end
}, {__index = _G})

--- Lua command history.
-- It has a numeric `pos` field that indicates where in the history the user currently is.
local history = {pos = 0}

--- Evaluates as Lua code the current line or the text on the currently selected lines.
-- If the current line has a syntax error, it is ignored and treated as a line continuation.
function M.evaluate_repl()
	local s, e = buffer.selection_start, buffer.selection_end
	local code, last_line
	if s ~= e then -- use selected lines as code
		local i, j = buffer:line_from_position(s), buffer:line_from_position(e)
		if i < j then
			s = buffer:position_from_line(i)
			if buffer.column[e] > 1 then e = buffer:position_from_line(j + 1) end
		end
		code = buffer:text_range(s, e)
		last_line = buffer:line_from_position(e)
	else -- use line as input
		code = buffer:get_cur_line()
		last_line = buffer:line_from_position(buffer.current_pos)
	end

	local f, result = load('return ' .. code, 'repl', 't', env)
	if not f then f, result = load(code, 'repl', 't', env) end
	if not f and s == e then return false end -- multi-line chunk; propagate key
	buffer:goto_pos(buffer.line_end_position[last_line])
	buffer:new_line()
	if f then result = select(2, pcall(f)) end
	if result then
		buffer:add_text('--> ')
		if type(result) == 'table' then
			-- Pretty-print tables like ui.command_entry does.
			local items = {}
			for k, v in pairs(result) do items[#items + 1] = string.format('%s = %s', k, v) end
			table.sort(items)
			result = string.format('{%s}', table.concat(items, ', '))
			if view.edge_column > 0 and #result > view.edge_column then
				local indent = string.rep(' ', buffer.tab_width)
				result = string.format('{\n%s%s\n}', indent, table.concat(items, ',\n' .. indent))
			end
		end
		buffer:add_text(tostring(result):gsub('(\r?\n)', '%1--> '))
		buffer:new_line()
	end
	history[#history + 1] = code
	history.pos = #history + 1
	buffer:set_save_point()
end

-- Autocompleter function for the Lua REPL.
-- @function _G.textadept.editing.autocompleters.lua_repl
textadept.editing.autocompleters.lua_repl = function()
	local line, pos = buffer:get_cur_line()
	local symbol, op, part = line:sub(1, pos - 1):match('([%w_.]-)([%.:]?)([%w_]*)$')
	local ok, result = pcall((load(string.format('return (%s)', symbol), nil, 't', env)))
	if (not ok or type(result) ~= 'table') and symbol ~= '' then return end
	local cmpls = {}
	part = '^' .. part
	if not ok or symbol == 'buffer' or symbol == 'view' then
		local global_envs = not ok and {_G} or {_SCINTILLA} -- undocumented
		for i = 1, #global_envs do
			for k in pairs(global_envs[i]) do
				if type(k) == 'string' and k:find(part) then cmpls[#cmpls + 1] = k end
			end
		end
	else
		for k, v in pairs(result) do
			if type(k) == 'string' and k:find(part) and (op == '.' or type(v) == 'function') then
				cmpls[#cmpls + 1] = k
			end
		end
	end
	return #part - 1, cmpls
end

--- Cycle backward through command history, taking into account commands with multiple lines.
function M.cycle_history_prev()
	if buffer:auto_c_active() then return false end -- propagate
	if history.pos <= 1 then return end
	for _ in (history[history.pos] or ''):gmatch('\n') do
		buffer:line_delete()
		buffer:delete_back()
	end
	buffer:line_delete()
	history.pos = math.max(history.pos - 1, 1)
	buffer:add_text(history[history.pos])
end

--- Cycle forward through command history, taking into account commands with multiple lines.
function M.cycle_history_next()
	if buffer:auto_c_active() then return false end -- propagate
	if history.pos >= #history then return end
	for _ in (history[history.pos] or ''):gmatch('\n') do
		buffer:line_delete()
		buffer:delete_back()
	end
	buffer:line_delete()
	history.pos = math.min(history.pos + 1, #history)
	buffer:add_text(history[history.pos])
end

--- Clears the command history.
function M.clear_history() history = {pos = 0} end

--- Table of key bindings for the REPL.
-- @field keys

-- This separation is needed to prevent LDoc from parsing the following table.

M.keys = {
	['\n'] = M.evaluate_repl, --
	['\t'] = function() textadept.editing.autocomplete('lua_repl') end,
	['ctrl+up'] = M.cycle_history_prev, ['ctrl+p'] = M.cycle_history_prev, --
	['ctrl+down'] = M.cycle_history_next, ['ctrl+n'] = M.cycle_history_next
}

--- Returns whether or not a buffer is the REPL buffer.
local function is_repl_buf(buf) return buf._type == _L['[Lua REPL]'] end

--- Helper function for getting the REPL view.
local function get_repl_view()
	for _, view in ipairs(_VIEWS) do if is_repl_buf(view.buffer) then return view end end
end
--- Helper function for getting the REPL buffer.
local function get_repl_buffer()
	for _, buffer in ipairs(_BUFFERS) do if is_repl_buf(buffer) then return buffer end end
end

--- Register REPL keys.
local function register_keys()
	if keys.lua[next(M.keys)] then return end -- already registered
	for key, f in pairs(M.keys) do
		keys.lua[key] = function()
			if buffer._type == '[Lua REPL]' then return f() end
			return false -- propagate
		end
	end
end
events.connect(events.RESET_AFTER, register_keys)

--- Creates or switches to a Lua REPL.
-- @param[opt=false] new Create a new REPL even if one already exists.
function M.open(new)
	local repl_view, repl_buf = get_repl_view(), get_repl_buffer()
	if new or not (repl_view or repl_buf) then
		buffer.new()._type = '[Lua REPL]'
		buffer:set_lexer('lua')
		buffer:add_text('-- ' .. _L['Lua REPL']:gsub('[_&]', ''))
		buffer:new_line()
		buffer:set_save_point()
		register_keys()
	else
		if repl_view then
			ui.goto_view(repl_view)
		else
			view:goto_buffer(repl_buf)
		end
		buffer:document_end() -- in case it's been scrolled in the meantime
	end
end

-- Add REPL to Tools menu.
_L['Lua REPL'] = 'L_ua REPL'
table.insert(textadept.menu.menubar['Tools'], {''})
table.insert(textadept.menu.menubar['Tools'], {_L['Lua REPL'], M.open})

return M
