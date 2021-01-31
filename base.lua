#!/usr/bin/env lua
-- VLE - Visual Lua Editor.  Not to be confused with VLED. --

local vt = require("lib/iface")
local kbd = require("lib/kbd")
require("lib/vlerc")
local syntax = require("lib/syntax")

local args = {...}

local buffers = {}
local current = 1
-- TODO: possibly support terminal resizing?
local w, h
local insert = false

local function try_get_highlighter(name)
  name = name or "NEW"
  local ext = name:match("%.(.-)$")
  if not ext then
    return
  end
  local try = "/usr/share/VLE/"..ext..".vle"
  local also_try = os.getenv("HOME").."/.local/share/VLE/"..ext..".vle"
  local ok, ret = pcall(syntax.load, also_try)
  if ok then
    return ret
  else
    ok, ret = pcall(syntax.load, try)
    if ok then
      return ret
    else
      ok, ret = pcall(syntax.load, "syntax/"..ext..".vle")
      if ok then
        return ret
      end
    end
  end
  return nil
end

local function get_abs_path(file)
  local pwd = os.getenv("PWD")
  if file:sub(1,1) == "/" or not pwd then return file end
  return string.format("%s/%s", pwd, file):gsub("[\\/]+", "/")
end

local function read_file(file)
  local handle, err = io.open(file, "r")
  if not handle then
    io.stderr:write(err)
    return ""
  end
  local data = handle:read("a")
  handle:close()
  return data
end

local function write_file(file, data)
  local handle, err = io.open(file, "w")
  if not handle then io.stderr:write(err) return end
  handle:write(data)
  handle:close()
end

local function get_last_pos(file)
  local abs = get_abs_path(file)
  local pdata = read_file(os.getenv("HOME") .. "/.vle_positions")
  local pat = abs:gsub("[%[%]%(%)%^%$%%%+%*%*]", "%%%1") .. ":(%d+)\n"
  if pdata:match(pat) then
    local n = tonumber(pdata:match(pat))
    return n or 1
  end
  return 1
end

local function save_last_pos(file, n)
  local abs = get_abs_path(file)
  local escaped = abs:gsub("[%[%]%(%)%^%$%%%+%*%*]", "%%%1")
  local pat = "(" .. escaped .. "):(%d+)\n"
  local vp_path = os.getenv("HOME") .. "/.vle_positions"
  local data = read_file(vp_path)
  if data:match(pat) then
    data = data:gsub(pat, string.format("%%1:%d\n", n))
  else
    data = data .. string.format("%s:%d\n", abs, n)
  end
  io.stderr:write(data)
  write_file(vp_path, data)
end

local function mkbuffer(file)
  local n = #buffers + 1
  buffers[n] = {
    lines = {""},
    unsaved = false,
    cache = {},
    scroll = 0,
    line = 1,
    cursor = 0,
    name = file
  }
  buffers[n].highlighter = try_get_highlighter(file)
  if not file then
    return
  end
  local handle = io.open(file, "r")
  if not handle then
    return
  end
  buffers[n].lines = {}
  for line in handle:lines() do
    buffers[n].lines[#buffers[n].lines + 1]
        -- strip Windows line endings
        = line:gsub("\r", "")
  end
  buffers[n].lines[1] = buffers[n].lines[1] or ""
  handle:close()
  local og_pos = get_last_pos(file)
  buffers[n].line = og_pos
end

for i=1, #args, 1 do
  mkbuffer(args[i])
end
if #buffers == 0 then
  mkbuffer()
end

local function update_cursor(l)
  local buf = buffers[current]
  local line = buf.line
  local scroll = buf.scroll
  local from_end = buf.cursor
  local text_len = #buf.lines[line]
  local x, y, t = 1, 0, 0
  for i=scroll, line - 1, 1 do
    y = y + (l[i] or 0)
  end
  t = y
  y = y + 1
  x = text_len - from_end + 1
  while x > w do
    x = x - w
    y = y + 1
  end
  while y >= h - 1 do
    y = y - 1
    buf.scroll = buf.scroll + 1
  end
  vt.set_cursor(x, y)
end

-- status bar on bottom
-- -- MODE -- [---------] cy
local _blank = string.format("\27[%dm~\27[39m", rc.blank or 94)
local _insert = string.format("\27[%dm-- insert --\27[39m", rc.insert or 93)
local function redraw_buffer()
  vt.set_cursor(1, 1)
  local buf = buffers[current]
  local written = 0
  local line_len = {}
  for i=1, h - 1, 1 do
    vt.set_cursor(1, written + 1)
    local line = i + buf.scroll
    if buf.lines[line] then
      local lines = math.max(1, math.ceil(#buf.lines[line] / w))
      if written + lines >= h then
        break
      end
      line_len[line] = lines
--      if buf.cache[line] then goto continue end
      buf.cache[line] = true
      written = written + lines
      local ldata = buf.lines[line]
      if buf.highlighter then
        ldata = buf.highlighter(ldata)
      end
      io.write(ldata)
    elseif not buf.cache[line] then
      written = written + 1
      io.write(_blank)
    end
    io.write("\27[K")
    ::continue::
    if written >= h then break end
  end
  vt.set_cursor(1, h)
  if insert then
    io.write("\27[2K", _insert)
  end
  vt.set_cursor(w - 12, h)
  io.write(string.format("\27[K%d,%d", buf.line, #buf.lines[buf.line] - buf.cursor + 1))
  update_cursor(line_len)
end

local function wrap(buf)
  if #buf.lines == 0 then
    buf.lines[1] = ""
  end
  if buf.line < 1 then
    buf.line = 1
  end
  if buf.line > #buf.lines then
    buf.line = #buf.lines
  end
  if buf.cursor > #buf.lines[buf.line] then
    buf.cursor = #buf.lines[buf.line]
  end
  if buf.cursor < 0 then
    buf.cursor = 0
  end
  while buf.line - 1 < buf.scroll and buf.scroll > 0 do
    buf.scroll = buf.scroll - 1
    buf.cache = {}
  end
  while (buf.line - h) + 1 > buf.scroll do
    buf.scroll = buf.scroll + 1
    buf.cache = {}
  end
end

local function process(key)
  local buf = buffers[current]
  local line = buf.line
  buf.cache[line] = nil
  local ltext = buf.lines[line]
  local cursor = buf.cursor
  if key == "backspace" then
    if #ltext > 0 then
      if cursor == #ltext then
        for i=line, h - (buf.scroll + line), 1 do
          buf.cache[line] = nil
        end
        local old = cursor
        local tmp = table.remove(buf.lines, line)
        buf.line = line - 1
        wrap(buf)
        line = buf.line
        buf.lines[line] = buf.lines[line] .. tmp
        buf.cursor = math.min(old, #buf.lines[line])
      else
        buf.lines[line] = ltext:sub(1, #ltext - cursor - 1) .. ltext:sub(#ltext - cursor + 1)
      end
    elseif line > 0 then
      table.remove(buf.lines, line)
      buf.cursor = 0
      wrap(buf)
      process("up")
    end
    buf.unsaved = true
  elseif key == "return" then
    local ident = ltext:match("^(%s+)") or ""
    for i=line, h - (buf.scroll + line), 1 do
      buf.cache[line] = nil
    end
    if cursor == 0 then
      table.insert(buf.lines, line + 1, (" "):rep(#ident))
      buf.line = line + 1
    else
      local tmp = ltext:sub(#ltext - cursor + 1)
      table.insert(buf.lines, line + 1, (" "):rep(#ident) .. tmp)
      buf.lines[line] = ltext:sub(1, #ltext - cursor)
      buf.line = line + 1
    end
    buf.unsaved = true
    wrap(buf)
  elseif key == "left" then
    if cursor < #ltext then
      buf.cursor = cursor + 1
    end
  elseif key == "right" then
    if cursor > 0 then
      buf.cursor = cursor - 1
    end
  elseif key == "up" then
    if line > 1 then
      local dfe = #(buf.lines[line] or "") - cursor
      buf.line = line - 1
      buf.cursor = #buf.lines[buf.line] - dfe
      wrap(buf)
    end
  elseif key == "down" then
    if line < #buf.lines then
      local dfe = #(buf.lines[line] or "") - cursor
      buf.line = line + 1
      buf.cursor = #buf.lines[buf.line] - dfe
      wrap(buf)
    end
  elseif #key == 1 then
    buf.lines[line] = ltext:sub(1, #ltext - cursor) .. key .. ltext:sub(#ltext - cursor + 1)
    buf.unsaved = true
  end
  redraw_buffer()
end

local commands
local function getinput(pref)
  vt.set_cursor(1, h)
  io.write("\27[2K", pref or ":")
  local buf = ""
  while true do
    vt.set_cursor(2, h)
    io.write(buf.." \27[D")
    local key, flags = kbd.get_key()
    flags = flags or {}
    if not (flags.ctrl or flags.alt) then
      if key == "backspace" then
        if #buf == 0 then return "" end
        buf = buf:sub(1, -2)
      else
        buf = buf .. key
      end
    elseif flags.ctrl and key == "m" then
      return buf
    end
  end
end

local function swr(...)
  io.write("\27[2K\27[G", ...)
  io.write("\27[39;49m")
end

commands = {
  ["^(%d+)$"] = function(n)
    local buf = buffers[current]
    n = tonumber(n) or buf.line
    buf.line = n
    wrap(buf)
  end,
  ["^b(%d+)$"] = function(n)
    n = tonumber(n) or 0
    if not buffers[n] then
      swr("\27[101;97mE: no such buffer")
      return
    end
    current = n
  end,
  ["^c(!?)$"] = function(skip)
    if buffers[current].unsaved and skip == "" then
      swr("\27[101;97mE: unsaved work; :c! to override")
      return
    end
    save_last_pos(buffers[current].name, buffers[current].line)
    table.remove(buffers, current)
    current = math.max(1, #buffers)
    if #buffers == 0 then
      commands["^q!$"]()
    end
  end,
  ["^d(%d-)$"] = function(n)
    n = tonumber(n) or 1
    if n < 1 then
      swr("\27[101;97mE: positive count required")
      return
    end
    local buf = buffers[current]
    for i=1, n, 1 do
      table.remove(buf.lines, buf.line)
      wrap(buf)
    end
    buf.unsaved = true
  end,
  ["^move ([%+%-]?)(%d-)$"] = function(sym, num)
    num = tonumber(num)
    if not num then
      swr("\27[101;97mE: invalid range")
      return
    end
    if sym == "-" then
      num = -num
      if num < 0 then num = num + 1 end -- why vim does this idk but this is
                                        -- largely a vim clone so i'll do it
                                        -- here too.  Maybe vi did it first?
    end
    local buf = buffers[current]
    if buf.line + num < 1 then
      return
    end
    local ltext = table.remove(buf.lines, buf.line)
    table.insert(buf.lines, buf.line + num, ltext)
    buf.line = buf.line + num
    wrap(buf)
  end,
  ["^n ([^ ]+)$"] = function(name)
    mkbuffer(name)
    current = #buffers
    swr("Created buffer ", #buffers)
  end,
  ["^(%%?)s/(.+)/(.+)/$"] = function(g, search, rep)
    local buf = buffers[current]
    if g == "%" then
      for i=1, #buf.lines, 1 do
        buf.lines[i] = buf.lines[i]:gsub(search, rep) or buf.lines[i]
      end
    else
      local ltext = buf.lines[buf.line]
      buf.lines[buf.line] = ltext:gsub(search, rep) or ltext
    end
  end,
  ["^w$"] = function()
    commands["^w ([^ ]+)$"](buffers[current].name)
  end,
  ["^w ([^ ]+)$"] = function(name)
    if not name then
      swr("\27[101;97mE: no filename\27[39;49m")
      return
    end
    local handle, err = io.open(name, "w")
    if not handle then
      swr("\27[101;97mE: ", err, "\27[39;49m")
      return
    end
    local data = table.concat(buffers[current].lines, "\n") .. "\n"
    handle:write(data)
    handle:close()
    swr("\"", name, "\", ", tostring(#buffers[current].lines), "L, ", #data, "B written")
    buffers[current].unsaved = false
  end,
  ["^q$"] = function()
    for k, v in pairs(buffers) do
      if v.unsaved then
        swr("\27[101;97mE: unsaved work; :q! to override\27[39;49m")
        return
      end
    end
    commands["^q!$"]()
  end,
  ["^q!$"] = function()
    -- should work on both apotheosis and real-world systems
    io.write("\27[2J\27[1;1H\27[m")
    if (not os.getenv("TERM")) or os.getenv("TERM"):match("OpenComputers") then
      io.write("\27(r\27(L\27[m")
    end
    for k, v in pairs(buffers) do
      if not v.unsaved then
        save_last_pos(v.name, v.line)
      end
    end
    os.execute("stty sane")
    os.exit(0)
  end,
  ["^wc$"] = function()
    commands["^w$"]()
    commands["^c(!?)$"]()
  end,
  ["^wq$"] = function()
    commands["^w$"]()
    commands["^q$"]()
  end
}

os.execute("stty raw -echo")
io.write("\27[2J\27[1;1H")
if (not os.getenv("TERM")) or os.getenv("TERM"):match("OpenComputers") then
  io.write("\27(R\27(l\27[8m")
end

w, h = vt.get_term_size()
-- ugly but it works!
process("down")
process("up")

local last_pat = ""
while true do
  redraw_buffer()
  local key, flags = kbd.get_key()
  flags = flags or {}
  if flags.ctrl then
    if key == "i" then
      insert = not insert
      vt.set_cursor(1, h)
      io.write("\27[2K")
    elseif key == "h" and insert then
      process("backspace")
    elseif key == "m" and insert then
      process("return")
    end
  elseif (key == "i" or key == "a") and not insert then
    insert = true
  elseif key == "up" or key == "down" or key == "left" or key == "right" or insert then
    process(key)
  elseif key == ":" then
    local cmd = getinput(":")
    for k, v in pairs(commands) do
      if cmd:match(k) then
        v(cmd:match(k))
      end
    end
  elseif key == "/" then
    local search = getinput("/")
    if #search == 0 then search = last_pat end
    if #search > 0 then
      last_pat = search
      local found = false
      local buf = buffers[current]
      for i=buf.line+1, #buf.lines, 1 do
        if buf.lines[i]:match(search) then
          buf.line = i
          found = true
          wrap(buf)
          break
        end
      end
      if not found then
        for i=1, #buf.lines, 1 do
          if buf.lines[i]:match(search) then
            buf.line = i
            found = true
            wrap(buf)
            swr("\27[91mSearch hit BOTTOM, continuing at TOP")
            break
          end
        end
      end
    end
  end
end
