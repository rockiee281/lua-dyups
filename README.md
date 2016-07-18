## Name
A lua module for dynamic upstream and health check

1. consistent hash
2. lua upstream

## Synopsis Sample

```
upstream test_001 {
    server 0.0.0.1; # just a place holder

    balancer_by_lua_block {
        local dyups = require "resty.dyups"
        dyups.set_current_peer(tostring(ngx.now()))
    }

    keepalive 10;
}

lua_shared_dict dyups 1m;
lua_socket_log_errors off;
init_worker_by_lua_block {
    local m = require("resty.dyups")
    m.init('{"action":"reset","upstream":"test_001","server_list":[{"name":"127.0.0.1:8002","weight":1},{"name":"127.0.0.1:8003","weight":2}],"healthcheck":{"on":true,"http_req":"GET /hello HTTP/1.0\r\nHost: qunar.com\r\n\r\n"}}')
                                                                                                }
```
