local b = require "ngx.balancer"
local hc = require "resty.dyups.healthcheck"
local cjson = require "cjson"
local chash = require "resty.chash"

local _M = {
    _VERSION = '0.01'
}

local sub = string.sub
local re_find = ngx.re.find
local dict = ngx.shared.dyups

local healthcheck_default_config = {
    shm = "healthcheck",  -- defined by "lua_shared_dict"
    upstream = "foo.com", -- defined by "upstream"
    type = "http",
    http_req = "GET /healthcheck.html HTTP/1.0\r\nHost: qunar.com\r\n\r\n",
    -- raw HTTP request for checking
    interval = 2000,  -- run the check cycle every 2 sec
    timeout = 1000,   -- 1 sec is the timeout for network operations
    fall = 3,  -- # of successive failures before turning a peer down
    rise = 2,  -- # of successive successes before turning a peer up
    valid_statuses = {200, 302},  -- a list valid HTTP status code
    concurrency = 10,  -- concurrency level for test requests
}

local function get_up_servers(server_list)
    local up_servers = {}
    for i, server in pairs(server_list) do
        if not server.down then
            table.insert(up_servers, server)
        end
    end

    return up_servers
end

function _M.set_current_peer(hash_key)
    if not ngx.ctx.tries then
        ngx.ctx.tries = 0
    end

    if ngx.ctx.tries < 2 then
        local ok, err = b.set_more_tries(1)
        if not ok then
            return error("failed to set more tries: ", err)
        elseif err then
            ngx.log(ngx.WARN, "set more tries: ", err)
        end
    end

    ngx.ctx.tries = ngx.ctx.tries + 1

    local status = dict:get("status_changed")
    if status then
        local server_list = cjson.decode(dict:get("test_001"))
        chash.init(get_up_servers(server_list))
        dict:delete("status_changed")
    end
    local name = chash.get_upstream(hash_key)
    local p = {}

    if name then
        local from, to, err = re_find(name, [[^(.*):\d+$]], "jo", nil, 1)
        if from then
            p.host = sub(name, 1, to)
            p.port = tonumber(sub(name, to + 2))
        end
    end

    b.set_current_peer(p.host, p.port)
end

local function check_server_config(config_str)
    local ok, config = pcall(cjson.decode, config_str)
    if not ok then
        ngx.log(ngx.ERR, "server config format error: JSON parsed error.")
        return nil
    end

    return config
end

local function enable_healthcheck(config)
    local healthcheck_config = healthcheck_default_config
    for k, v in pairs(config.healthcheck) do
        healthcheck_config[k] = v
    end
    config.healthcheck = healthcheck_config
    local ok, err = hc.spawn_checker(config)
    if not ok then
        ngx.log(ngx.ERR, "failed to spawn health checker: ", err)
        return
    end
end

function _M.init(server_config_str)
    local server_config = check_server_config(server_config_str)
    if server_config == nil then
        ngx.log(ERR, "server_config format error")
        return
    end

    local server_list = server_config.server_list
    local up_server_list = get_up_servers(server_list)
    if #up_server_list == 0 then
        ngx.log(ngx.ERR, "Init servers failed: there's no live servers in this upstream")
        return
    end
    chash.init(up_server_list)
    if server_config.healthcheck.on == true then
        enable_healthcheck(server_config)
    end
end

return _M
