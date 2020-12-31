#!/usr/bin/env lua
-- VLE - Visual Lua Editor.  Not to be confused with VLED. --

local vt = require("term/iface")
local kbd = require("term/kbd")

local args = {...}

local buffers = {}
local current = 1
-- TODO: possibly support terminal resizing?
local w, h
local insert = false

local function mkbuffer(file)
  local n = #buffers + 1
  buffers[n] = {lines = {""}, unsaved = false, cached = {}, scroll = 0, line = 1, cursor = 0}
  local handle = io.open(file, "r")
  if not handle then
    return
  end
end

for i=1, #args, 1 do
  mkbuffer(args[i])
end

local function update_cursor(l)
  local buf = buffers[current]
  local line = buf.line
  local scroll = buf.scroll
  local from_end = buf.cursor
  local text_len = #buf.lines[line]
  local y = 0
  for i=scroll, line - 1, 1 do
    y = y + (l[i] or 0)
  end
  vt.set_cursor(1, y)
  io.write(string.rep("\27[C", text_len - from_end))
end

-- status bar on bottom
-- -- MODE -- [---------] cy
local function redraw_buffer()
  vt.set_cursor(1, 1)
  local buf = buffers[current]
  local written = 0
  local line_len = {}
  for i=1, h, 1 do
    vt.set_cursor(1, i)
    local line = i + buf.scroll
    io.write("\27[2K")
    if buf.lines[line] then
      local lines = math.max(1, math.ceil(#buf.lines[line] / w))
      if written + lines > h then
        break
      end
      line_len[line] = lines
      written = written + lines
      io.write(buf.lines[line])
    else
      written = written + 1
      io.write("\27[94m~\27[39m")
    end
    if written >= h then break end
  end
  vt.set_cursor(1, h)
  if insert then
    io.write("\27[2K\27[93m-- insert --\27[39m")
  else
    io.write("\27[2K")
  end
  vt.set_cursor(w - 12, h)
  io.write(string.format("%d", buf.line))
  update_cursor(line_len)
end

local function process(key)
  local buf = buffers[current]
  local line = buf.line
  local ltext = buf.lines[line]
  local dfe = buf.cursor
  if key == "backspace" then
    buf.lines[line] = ltext:sub(1, #ltext - cursor - 1) .. ltext:sub(1, #ltext - cursor)
  elseif key == "left" then
  elseif key == "right" then
  elseif key == "up" then
  elseif key == "down" then
  end
end

local function getcommand()
  vt.set_cursor(1, h)
  io.write("\27[2K:")
  local buf = ""
  while true do
    vt.set_cursor(2, h)
    io.write(buf.." \27[D")
    local key, flags = kbd.get_key()
    flags = flags or {}
    if not (flags.ctrl or flags.alt) then
      if key == "backspace" then
        buf = buf:sub(1, -2)
      else
        buf = buf .. key
      end
    elseif flags.ctrl and key == "m" then
      return buf
    end
  end
end

local commands = {
  ["^q$"] = function()
    -- should work on both apotheosis and real-world systems
    io.write("\27[2J\27[1;1H\27(r\27(L\27[m")
    os.execute("stty sane")
    os.exit(0)
  end
}

os.execute("stty raw -echo")
io.write("\27[2J\27[1;1H\27(R\27(l")
-- uncomnent this line if running on Apotheosis
-- io.write("\27[8m")
w, h = vt.get_term_size()

while true do
  redraw_buffer()
  local key, flags = kbd.get_key()
  flags = flags or {}
  if flags.ctrl then
    if key == "i" then
      insert = not insert
    elseif key == "h" and insert then
      process("backspace")
    end
  elseif insert then
    process(key)
  elseif key == ":" then
    local cmd = getcommand()
    for k, v in pairs(commands) do
      if cmd:match(k) then
        v(cmd:match(k))
      end
    end
  end
end
