# Copyright 2014-2020 Mitchell. See LICENSE.

# Documentation.

ta = ../..
cwd = $(shell pwd)
docs: luadoc README.md
README.md: init.lua
	cd $(ta)/scripts && luadoc --doclet markdowndoc $(cwd)/$< > $(cwd)/$@
	sed -i -e '1,+4d' -e '6c# Lua REPL' -e '7d' -e 's/^##/#/;' $@
luadoc: init.lua
	cd $(ta)/modules && luadoc -d $(cwd) --doclet lua/tadoc $(cwd)/$< \
		--ta-home=$(shell readlink -f $(ta))
	sed -i 's/_HOME.\+\?_HOME/_HOME/;' tags

# Releases.

ifneq (, $(shell hg summary 2>/dev/null))
  archive = hg archive -X ".hg*" $(1)
else
  archive = git archive HEAD --prefix $(1)/ | tar -xf -
endif

release: lua_repl ; zip -r $<.zip $< -x "$</.git*" && rm -r $<
lua_repl: ; $(call archive,$@)
