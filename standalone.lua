#!/usr/bin/env lua
local function rf(f, n, s)
  local handle = assert(io.open(f))
  local data = ""
  if n then
    for i=1, n, 1 do data = data .. handle:read("L") end
    if s then data = handle:read("a") end
  else
    data = handle:read("a")
  end
  handle:close()
  return data
end

local function wf(f, d)
  local handle = assert(io.open(f, "w"))
  handle:write(d)
  handle:close()
end

wf("vle", rf("base.lua", 3) .. rf("lib/iface.lua", 27) .. rf("lib/kbd.lua", 62)
  .. "local rc\n" .. rf("lib/vlerc.lua") .. rf("lib/syntax.lua", 203)
  .. rf("base.lua", 7, true))
