OPENRESTY_PREFIX=/opt/openresty
LUA_VERSION=5.1

PREFIX ?=          /opt/openresty/luajit
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR ?=     $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL ?= install

.PHONY: all install

all: ;

install: all
	$(INSTALL) -d ${OPENRESTY_PREFIX}/lualib/resty/dyups/
	$(INSTALL) lib/resty/*.lua ${OPENRESTY_PREFIX}/lualib/resty/
	$(INSTALL) lib/resty/dyups/*.lua ${OPENRESTY_PREFIX}/lualib/resty/dyups/

