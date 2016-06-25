OPENRESTY_PREFIX=/opt/openresty
LUA_VERSION=5.1

PREFIX ?=          /opt/openresty/luajit
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all install

all: ;

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/resty/
	$(INSTALL) *.lua $(DESTDIR)/$(LUA_LIB_DIR)/resty/
