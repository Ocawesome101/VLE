-- VLERC parsing

_G.rc = {}

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
    ct = "constant",
    cm = "comment",
    st = "string",
    kw = "keyword",
    kc = "keychar",
  }
  local colors = {
    red = 31,
    green = 32,
    yellow = 33,
  }
  
  local function parse(line)
    local words = split(line)
    if #words < 1 then return end
    local c = pop(words)
    -- color keyword 32
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
    end
  end
end
