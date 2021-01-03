-- basic terminal interface library --

local vt = {}

function vt.set_cursor(x, y)
  io.write(string.format("\27[%d;%dH", y, x))
end

function vt.get_cursor()
  --os.execute("stty raw -echo")
  io.write("\27[6n")
  local resp = ""
  repeat
    local c = io.read(1)
    resp = resp .. c
  until c == "R"
  local y, x = resp:match("\27%[(%d+);(%d+)R")
  --os.execute("stty sane")
  return tonumber(x), tonumber(y)
end

function vt.get_term_size()
  local cx, cy = vt.get_cursor()
  vt.set_cursor(9999, 9999)
  local w, h = vt.get_cursor()
  vt.set_cursor(cx, cy)
  return w, h
end

return vt
