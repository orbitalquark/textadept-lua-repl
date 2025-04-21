# Lua REPL

A Textadept module for loading an interactive Lua REPL using the editor's Lua State, similar
to Lua's interactive REPL.

This is an alternative to the single-line Lua command entry.

Install this module by copying it into your *~/.textadept/modules/* directory or Textadept's
*modules/* directory, and then putting the following in your *~/.textadept/init.lua*:

```lua
local lua_repl = require('lua_repl')
```

Select "Tools > Lua REPL" to open the REPL. Typing the Enter key on any line evaluates that
line, unless that line is a continuation line. In that case, when finished, select the lines
to evaluate and type Enter to evaluate the entire chunk.

Tab completion is available, as is cycling through history with the `Ctrl+Up`/`Ctrl+Down`
and `Ctrl+P` and `Ctrl+N` keys.

**Note:** if the Language Server Protocol (LSP) module is enabled, any completions coming
from that module are separate from this module's completions.

Lines may be optionally prefixed with '=' (similar to the Lua prompt) to print a result.

<a id="lua_repl.cycle_history_next"></a>
## `lua_repl.cycle_history_next`()

Cycle forward through command history, taking into account commands with multiple lines.

<a id="lua_repl.cycle_history_prev"></a>
## `lua_repl.cycle_history_prev`()

Cycle backward through command history, taking into account commands with multiple lines.

<a id="lua_repl.evaluate_repl"></a>
## `lua_repl.evaluate_repl`()

Evaluates as Lua code the current line or the text on the currently selected lines.

If the current line has a syntax error, it is ignored and treated as a line continuation.

<a id="lua_repl.history"></a>
## `lua_repl.history`

Lua command history.

It has a numeric `pos` field that indicates where in the history the user currently is.

Fields:
- `pos`: 

<a id="lua_repl.keys"></a>
## `lua_repl.keys`

Table of key bindings for the REPL.

<a id="lua_repl.open"></a>
## `lua_repl.open`([*new*=false])

Creates or switches to a Lua REPL.

Parameters:
- *new*:  Create a new REPL even if one already exists.



