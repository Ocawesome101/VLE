-- VLERC parsing

rc = {syntax=true,cachelastline=true,commands={},aliases={}}

do
  local function split(line)
    local words = {}
    for word in line:gmatch("[^ ]+") do
      words[#words + 1] = word
    end
    return words
  end

  local function pop(t) return table.remove(t, 1) end

  local fields = {
    bi = "builtin",
    bn = "blank",
    ct = "constant",
    cm = "comment",
    is = "insert",
    kw = "keyword",
    kc = "keychar",
    st = "string",
  }
  local colors = {
    black = 30,
    gray = 90,
    lightGray = 37,
    red = 91,
    green = 92,
    yellow = 93,
    blue = 94,
    magenta = 95,
    cyan = 96,
    white = 97
  }
  
  local function parse(line)
    local words = split(line)
    if #words < 1 then return end
    local c = pop(words)
    -- color keyword 32
    -- co kw green
    if c == "color" or c == "co" and #words >= 2 then
      local field = pop(words)
      field = fields[field] or field
      local color = pop(words)
      if colors[color] then
        color = colors[color]
      else
        color = tonumber(color)
      end
      if not color then return end
      rc[field] = color
    elseif c == "cachelastline" then
      local arg = pop(words)
      arg = (arg == "yes") or (arg == "true") or (arg == "on")
      rc.cachelastline = arg
    elseif c == "syntax" then
      local arg = pop(words)
      rc.syntax = (arg == "yes") or (arg == "true") or (arg == "on")
    elseif c == "macro" then -- basic macro support
      local mt = pop(words)
      local cpat = pop(words)
      if mt == "function" then
        local fnsrc = table.concat(words, " ", 1, #words)
        local ok, err = load("return " .. fnsrc, "=macro("..cpat..")", "bt", _G)
        if ok then
          ok, err = pcall(ok)
        end
        if not ok then
          io.stderr:write("error loading macro: ", err, "\n")
          io.stderr:write("macro source: ", fnsrc, "\n")
          io.read()
        end
        if type(err) == "function" then
          rc.commands[cpat] = err
        end
      elseif mt == "alias" then
        local alias = pop(words)
        rc.aliases[cpat] = alias
      end
    end
  end

  local home = os.getenv("HOME")
  local handle = io.open(home .. "/.vlerc", "r")
  if not handle then goto anyways end
  for line in handle:lines() do
    parse(line)
  end
  handle:close()
  ::anyways::
end
