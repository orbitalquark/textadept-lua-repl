-- Copyright 2020-2025 Mitchell. See LICENSE.

local lua_repl = require('lua_repl')

test('lua_repl.open should open a REPL', function()
	lua_repl.open()

	test.assert_equal(buffer._type, _L['[Lua REPL]'])
	test.assert_equal(buffer.lexer_language, 'lua')
end)

test('lua_repl.open should switch to an active REPL', function()
	lua_repl.open()
	view:goto_buffer(-1)

	lua_repl.open()

	test.assert_equal(buffer._type, _L['[Lua REPL]'])
	test.assert_equal(#_BUFFERS, 2)
end)

test('lua_repl.open should switch to a REPL active in another view', function()
	lua_repl.open()
	view:split()
	view:goto_buffer(-1)

	lua_repl.open()

	test.assert_equal(buffer._type, _L['[Lua REPL]'])
	test.assert_equal(_VIEWS[view], 1)
	test.assert_equal(_BUFFERS[_VIEWS[2].buffer], 1)
end)

local function get_previous_line() return buffer:get_line(buffer.line_count - 1):gsub('\r?\n', '') end
local function get_current_line() return buffer:get_line(buffer.line_count) end

test('lua_repl.open should always open a new REPL if told to do so', function()
	lua_repl.open()
	lua_repl.open(true)

	test.assert_equal(#_BUFFERS, 3)
end)

test('Enter should evaluate the current line', function()
	lua_repl.open()

	test.type('1+2\n')

	test.assert_equal(get_previous_line(), '--> 3')
end)

test('Enter should evaluate selected lines', function()
	lua_repl.open()

	test.type('1+\n')
	test.type('2')
	buffer:line_up_extend()
	test.type('\n')

	test.assert_equal(get_previous_line(), '--> 3')
end)

test('lua_repl.evaluate_repl should pretty-print tables', function()
	lua_repl.open()

	test.type('{1,2,3}\n')

	test.assert_equal(get_previous_line(), '--> {1 = 1, 2 = 2, 3 = 3}')
end)

test('lua_repl.evaluate_repl should allow wrapping pretty-printed tables', function()
	lua_repl.open()
	local _<close> = test.mock(view, 'edge_column', 80)

	test.type('buffer\n')

	test.assert_equal(get_previous_line(), '--> }') -- result over multiple lines
end)

test('lua_repl.evaluate_repl should use its own print function', function()
	lua_repl.open()

	test.type('print(1,2,3)\n')

	test.assert_equal(get_previous_line(), '--> 1\t2\t3')
end)

test('Tab should show completions', function()
	lua_repl.open()
	buffer:add_text('string.') -- avoid triggering LSP
	local auto_c_show = test.stub()
	local _<close> = test.mock(buffer, 'auto_c_show', auto_c_show)

	test.type('\t')

	test.assert_equal(auto_c_show.called, true)
	test.assert_contains(auto_c_show.args[3], 'byte')
end)

test('Tab completions should include methods', function()
	lua_repl.open()
	buffer:add_text('buffer:get') -- avoid triggering LSP
	local auto_c_show = test.stub()
	local _<close> = test.mock(buffer, 'auto_c_show', auto_c_show)

	test.type('\t')

	test.assert_equal(auto_c_show.called, true)
	test.assert_contains(auto_c_show.args[3], 'get_cur_line')
end)

test('ctrl+p should cycle backwards through history', function()
	lua_repl.open()
	test.type('1+2\n')

	test.type('{1,2,3}')
	test.type('ctrl+p')

	test.assert_equal(get_current_line(), '1+2')
end)

test('ctrl+p history should support multi-line input', function()
	lua_repl.open()
	test.type('1+\n')
	test.type('2')
	buffer:line_up_extend()
	test.type('\n')

	test.type('ctrl+p')

	test.assert_equal(get_previous_line(), '1+')
	test.assert_equal(get_current_line(), '2')
end)

test('ctrl+p should stop cycling when there is no prior history', function()
	lua_repl.open()
	test.type('1+2\n')
	test.type('ctrl+p')

	test.type('ctrl+p')

	test.assert_equal(get_current_line(), '1+2')
end)

test('ctrl+n should cycle forward through history', function()
	lua_repl.open()
	test.type('1+2\n')
	test.type('{1,2,3}\n')
	test.type('ctrl+p')
	test.type('ctrl+p')

	test.type('ctrl+n')

	test.assert_equal(get_current_line(), '{1,2,3}')
end)

test('ctrl+n history should support multi-line input', function()
	lua_repl.open()
	test.type('1+\n')
	test.type('2')
	buffer:line_up_extend()
	test.type('\n')
	test.type('{1,2,3}\n')
	test.type('ctrl+p')
	test.type('ctrl+p')

	test.type('ctrl+n')

	test.assert_equal(get_previous_line(), '--> {1 = 1, 2 = 2, 3 = 3}')
	test.assert_equal(get_current_line(), '{1,2,3}')
end)

test('ctrl+n should stop cycling when there is no more history', function()
	lua_repl.open()
	test.type('1+2\n')
	test.type('{1,2,3}\n')
	test.type('ctrl+p')
	test.type('ctrl+p')
	test.type('ctrl+n')

	test.type('ctrl+n')

	test.assert_equal(get_current_line(), '{1,2,3}')
end)

test('lua_repl functionality should survive a reset #skip', function()
	lua_repl.open()

	reset()
	test.type('1+2')

	test.assert_equal(get_previous_line(), '--> 3')
end)

-- Coverage tests.

test('Enter should not do anything special in a Lua buffer', function()
	buffer:set_lexer('lua')

	test.type('\n')

	test.assert_equal(buffer.line_count, 2)
end)
