-- keyboard interface with standard VT100 terminals --

local kbd = {}

local patterns = {
  ["1;7."] = {ctrl = true, alt = true},
  ["1;5."] = {ctrl = true},
  ["1;3."] = {alt = true}
}

local substitutions = {
  A = "up",
  B = "down",
  C = "right",
  D = "left"
}

-- this is a neat party trick.  works for all alphabetical characters.
local function get_char(ascii)
  return string.char(96 + ascii:byte())
end

function kbd.get_key()
--  os.execute("stty raw -echo")
  local data = io.read(1)
  local key, flags
  if data == "\27" then
    local intermediate = io.read(1)
    if intermediate == "[" then
      data = ""
      repeat
        local c = io.read(1)
        data = data .. c
        if c:match("[a-zA-Z]") then
          key = c
        end
      until c:match("[a-zA-Z]")
      flags = {}
      for pat, keys in pairs(patterns) do
        if data:match(pat) then
          flags = keys
        end
      end
      key = substitutions[key] or "unknown"
    else
      key = io.read(1)
      flags = {alt = true}
    end
  elseif data:byte() > 31 and data:byte() < 127 then
    key = data
  elseif data:byte() == 127 then
    key = "backspace"
  else
    key = get_char(data)
    flags = {ctrl = true}
  end
  --os.execute("stty sane")
  return key, flags
end

return kbd
