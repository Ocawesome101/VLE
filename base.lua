#!/usr/bin/env lua
-- VLE - Visual Lua Editor.  Not to be confused with VLED. --

local vt = require("term/iface")
local kbd = require("term/kbd")

local args = {...}

local buffers = {}
local current = 1
-- TODO: possibly support terminal resizing?
local w, h = vt.get_resolution()
local insert = false

local function mkbuffer(file)
  local n = buffers[#buffers + 1]
  buffers[n] = {lines = {""}, unsaved = false, cached = {}, scroll = 0, line = 1, cursor = 0}
  local handle = io.open(file, "r")
  if not handle then
    return
  end
end

local function update_cursor()
end

local function draw_line()
end

-- status bar on bottom
-- -- MODE -- [---------] cy
local function redraw_buffer()
  vt.set_cursor(1, 1)
  local buf = buffers[current]
  for i=1, h, 1 do
  end
  vt.set_cursor(1, h)
  if insert then
    io.write("\27[93m-- insert --\27[39m")
  end
  vt.set_cursor(w - 12, h)
  io.write(string.format("%d", buf.line))
  update_cursor()
end

local commands = {
  ["^q$"] = function()
    -- should work on both apotheosis and real-world systems
    io.write("\27[2J\27[1;1H\27(r\27(L")
    os.execute("stty sane")
    os.exit(0)
  end
}

while true do
  redraw_buffer()
  local key, flags = kbd.get_key()
  if flags.control then
    if key == "i" then
      insert = not insert
    end
  elseif insert then
    process(key)
  elseif key == ":" then
    getcommand()
  end
end
