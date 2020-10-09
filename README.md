# Lua REPL

A Textadept module for loading an interactive Lua REPL using the editor's Lua
State, similar to Lua's interactive REPL.

This is an alternative to the single-line Lua command entry.

Install this module by copying it into your *~/.textadept/modules/* directory
or Textadept's *modules/* directory, and then putting the following in your
*~/.textadept/init.lua*:

    require('lua_repl')

Select "Tools > Lua REPL" to open the REPL. Typing the Enter key on any line
evaluates that line, unless that line is a continuation line. In that case,
when finished, select the lines to evaluate and type Enter to evaluate the
entire chunk.

Lines may be optionally prefixed with '=' (similar to the Lua prompt) to
print a result.

## Functions defined by `lua_repl`

<a id="lua_repl.complete_lua"></a>
### `lua_repl.complete_lua`()

Shows a set of Lua code completions for the current position.

<a id="lua_repl.cycle_history_next"></a>
### `lua_repl.cycle_history_next`()

Cycle forward through command history, taking into account commands with
multiple lines.

<a id="lua_repl.cycle_history_prev"></a>
### `lua_repl.cycle_history_prev`()

Cycle backward through command history, taking into account commands with
multiple lines.

<a id="lua_repl.evaluate_repl"></a>
### `lua_repl.evaluate_repl`()

Evaluates as Lua code the current line or the text on the currently selected
lines.
If the current line has a syntax error, it is ignored and treated as a line
continuation.


## Tables defined by `lua_repl`

<a id="lua_repl.history"></a>
### `lua_repl.history`

Lua command history.
It has a numeric `pos` field that indicates where in the history the user
currently is.

<a id="lua_repl.keys"></a>
### `lua_repl.keys`

Table of key bindings for the REPL.

---
