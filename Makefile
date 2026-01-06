# Copyright 2014-2026 Mitchell. See LICENSE.

# Documentation.

ta = ../..
cwd = $(shell pwd)
docs: README.md
README.md: init.lua
	cd $(ta)/scripts && ldoc --filter markdowndoc.ldoc $(cwd)/$< -- --title="Lua REPL" --single \
		> $(cwd)/$@

# Releases.

ifneq (, $(shell hg summary 2>/dev/null))
  archive = hg archive -X ".hg*" $(1)
else
  archive = git archive HEAD --prefix $(1)/ | tar -xf -
endif

release: lua_repl ; zip -r $<.zip $< -x "$</.git*" && rm -r $<
lua_repl: ; $(call archive,$@)
