-- library for basic syntax highlighting definitions --

local syntax = {}

do
  local keyword_color, builtin_color, const_color, str_color,
                                                          cmt_color, kchar_color
    = 91,            92,            95,         93,       90,        94

  local function esc(n)
    return string.format("\27[%dm", n)
  end

  keyword_color = esc(keyword_color)
  builtin_color = esc(builtin_color)
  kchar_color = esc(kchar_color)
  const_color = esc(const_color)
  str_color = esc(str_color)
  cmt_color = esc(cmt_color)
  
  local numpat = {}
  local keywords = {}
  local keychars = {}
  local constpat = {}
  local functions = {}
  local constants = {}
  local cprefix = "#"
  local function split(l)
    local words = {}
    for w in l:gmatch("[^ ]+") do
      words[#words + 1] = w
    end
    return words
  end
  local function parse_line(line)
    local words = split(line)
    local cmd = words[1]
    if not cmd then
      return
    elseif cmd == "keychars" then
      for i=2, #words, 1 do
        for c in words[i]:gmatch(".") do
          keychars[#keychars + 1] = c
        end
      end
    elseif cmd == "comment" then
      cprefix = words[2] or cprefix
    elseif cmd == "keywords" then
      for i=2, #words, 1 do
        keywords[words[i]] = true
      end
    elseif cmd == "const" then
      for i=2, #words, 1 do
        constants[words[i]] = true
      end
    elseif cmd == "builtin" then
      for i=2, #words, 1 do
        functions[words[i]] = true
      end
    elseif cmd == "constpat" and words[2] then
      constpat[#constpat + 1] = words[2]
    end
  end

  local function match_constant(w)
    if constants[w] then return true end
    for i=1, #constpat, 1 do
      if w:match(constpat[i]) then
        return true
      end
    end
    return false
  end

  local function mkhighlighter()
    local kchars = ""
    if #keychars > 0 then
      kchars = "[%" .. table.concat(keychars, "%") .. "]"
    end
    local function words(ln)
      local words = {}
      local ws, word = "", ""
      for char in ln:gmatch(".") do
        if (char:match(kchars) and #kchars > 0) or char:match("[\"'%s,]") then
          ws = char
          if #word > 0 then words[#words + 1] = word end
          if #ws > 0 then words[#words + 1] = ws end
          word = ""
          ws = ""
        else
          word = word .. char
        end
      end
      if #word > 0 then words[#words + 1] = word end
      if #ws > 0 then words[#words + 1] = ws end
      return words
    end

    local function highlight(line)
      local ret = "\27[39m"
      local in_str = false
      local in_cmt = false
      for i, word in ipairs(words(line)) do
        if word:match("[\"']") and not in_str and not in_cmt then
          in_str = true
          ret = ret .. str_color .. word
        elseif in_str then
          ret = ret .. word
          if word:match("[\"']") then
            ret = ret .. "\27[39m"
            in_str = false
          end
        elseif word:sub(1,#cprefix) == cprefix then
          in_cmt = true
          ret = ret .. cmt_color .. word
        elseif in_cmt then
          ret = ret .. word
        else
          local esc = (keywords[word] and keyword_color) or
                      (functions[word] and builtin_color) or
                      (match_constant(word) and const_color) or
                      (#kchars > 0 and word:match(kchars) and kchar_color) or ""
          ret = ret .. esc .. word .. (esc ~= "" and "\27[39m" or "")
        end
      end
      ret = ret .. "\27[39m"
      return ret
    end

    return highlight
  end

  function syntax.load(file)
    local handle = io.open(file)
    for line in handle:lines() do
      parse_line(line)
    end
    return mkhighlighter()
  end
end

return syntax
