local ffi      = require "ffi"
local ffi_cast = ffi.cast
local C        = ffi.C
local tonumber = tonumber

ffi.cdef[[
typedef unsigned char u_char;
uint32_t ngx_murmur_hash2(u_char *data, size_t len);
]]

local _M = {_VERSION = '0.01'}


function _M.murmur2(value)
    return tonumber(C.ngx_murmur_hash2(ffi_cast('uint8_t *', value), #value))
end

return _M
