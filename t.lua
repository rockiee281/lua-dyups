#!/bin/env lua
local chash=require("chash")
local cjson=require("cjson")
chash.add_upstream("123.1.1.1:8080")
chash.add_upstream("123.1.1.2:8080")
chash.add_upstream("123.1.1.3:8080")
chash.add_upstream("123.1.1.4:8080")
chash.add_upstream("123.1.1.5:8080")
chash.add_upstream("123.1.1.6:8080", 2)
--print(cjson.encode(chash.get_all_upstream()))

--chash.remove_upstream("123.1.1.4:8080")
--print(cjson.encode(chash.get_all_upstream()))

chash.init()

for i=1,10000 do
    print(chash.get_upstream(i))
end
