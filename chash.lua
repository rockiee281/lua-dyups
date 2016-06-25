#!/usr/bin/lua

-- origin by chenqi@2014/04/02
--[Reference]
--https://github.com/yaoweibin/ngx_http_consistent_hash
--https://github.com/davidm/lua-digest-crc32lua
--http://www.cnblogs.com/chenny7/p/3640990.html


local M = {}

local CONSISTENT_BUCKETS = 65535
local VIRTUAL_NODE = 160

local HASH_PEERS = {}
local CONTINUUM = {}
local BUCKETS = {}

local function hash_fn(key)
    local mmh2 = require "resty.murmurhash2"
    local val = mmh2.murmur2(key)
    return val;
end
--    local CRC = require('CRC32')
--    local val = CRC.crc32(key)
--    return val + 0x8fffffff

--    local hashlib = require('hashlib')
--    return hashlib.murmurhash64b(key .. '-')

-- in-place quicksort
function quicksort(array,compareFunc)  
    quick(array,1,#array,compareFunc)  
end  

function quick(array,left,right,compareFunc)  
    if(left < right ) then  
        local index = partion(array,left,right,compareFunc)  
        quick(array,left,index-1,compareFunc)  
        quick(array,index+1,right,compareFunc)  
    end  
end  
  
function partion(array,left,right,compareFunc)  
    local key = array[left] 
    local index = left  
    array[index],array[right] = array[right],array[index]
    local i = left  
    while i< right do  
        if compareFunc( key,array[i]) then  
            array[index],array[i] = array[i],array[index]
            index = index + 1  
        end  
        i = i + 1  
    end  
    array[right],array[index] = array[index],array[right]
    return index;  
end  

-- binary search
local function chash_find(point)
    local mid, lo, hi = 1, 1, #CONTINUUM
    while 1 do
        if point <= CONTINUUM[lo][2] or point > CONTINUUM[hi][2] then
            return CONTINUUM[lo]
        end

        -- test middle point
        mid = lo + math.floor((hi-lo)/2)

        -- perfect match
        if point <= CONTINUUM[mid][2] and point > (mid > 1 and CONTINUUM[mid-1][2] or 0) then
            return CONTINUUM[mid]
        end

        -- too low, go up
        if CONTINUUM[mid][2] < point then
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
end

local function chash_init(PEER_ARRAY)
    local n = #PEER_ARRAY
    HASH_PEERS = PEER_ARRAY
    if n == 0 then
        print("There is no backend servers")
        return
    end

    local C = {}
    for i,peer in ipairs(PEER_ARRAY) do
        for k=1, math.floor(VIRTUAL_NODE * peer['weight']) do
            local hash_data = peer['name'] .. "-" .. (k - 1)
	    --print(hash_data .. '|' .. hash_fn(hash_data))
            table.insert(C, {peer['name'], hash_fn(hash_data)})
        end
    end

    quicksort(C, function(a,b) return a[2] > b[2] end)
    CONTINUUM = C
--[[
    for i=1,#C do
        print(CONTINUUM[i][1],CONTINUUM[i][2])
    end
--]]

    local step = math.floor(0xFFFFFFFF / CONSISTENT_BUCKETS)

    BUCKETS = {}
    for i=1, CONSISTENT_BUCKETS do
        table.insert(BUCKETS, i, chash_find(math.floor(step * (i - 1))))
      --print(chash_find(math.floor(step * (i - 1)))[1])
      --print(i .. "|" .. BUCKETS[i][1] .. "|" .. BUCKETS[i][2])
    end

end
M.init = chash_init

local function chash_get_upstream_hash(point)
    return BUCKETS[(point % CONSISTENT_BUCKETS)+1][1]
end
M.get_upstream_hash = chash_get_upstream_hash

local function chash_get_upstream(key)
    local point = math.floor(hash_fn(key)) 
    return chash_get_upstream_hash(point)
end
M.get_upstream = chash_get_upstream
--
--local function chash_add_upstream(upstream, weight)
--    weight = weight or 1
--    table.insert(HASH_PEERS, {weight, upstream})
--end
--M.add_upstream = chash_add_upstream
--
---- remove upstream from HASH_PEERS
--local function chash_remove_upstream(upstream)
--    for i,peer in ipairs(HASH_PEERS) do
--        if peer[2] == upstream then
--	    table.remove(HASH_PEERS, i)
--	    --print('remove ' .. peer[2])
--	end
--    end
--end
--M.remove_upstream = chash_remove_upstream

local function chash_get_all_upstream()
    return HASH_PEERS
end
M.get_all_upstream = chash_get_all_upstream

return M
