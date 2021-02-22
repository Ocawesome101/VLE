-- library for basic syntax highlighting definitions --

local syntax = {}

do
  local 
  keyword_color,
  builtin_color,
  const_color,
  str_color,
  cmt_color,
  kchar_color
  =
  rc.keyword or 91,
  rc.builtin or 92,
  rc.constant or 95,
  rc.string or 93,
  rc.comment or 90,
  rc.keychar or 94

  local function esc(n)
    return string.format("\27[%dm", n)
  end

  keyword_color = esc(keyword_color)
  builtin_color = esc(builtin_color)
  kchar_color = esc(kchar_color)
  const_color = esc(const_color)
  str_color = esc(str_color)
  cmt_color = esc(cmt_color)
  
  local function split(l)
    local words = {}
    for w in l:gmatch("[^ ]+") do
      words[#words + 1] = w
    end
    return words
  end
  local function parse_line(line, numpat, keywords, keychars, constpat,
                                 functions, constants, operators, ocp, ost)
    local cprefix, strings = ocp or "#", not not ost
    local words = split(line)
    local cmd = words[1]
    if not cmd then
      return cprefix, strings
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
    elseif cmd == "strings" then
      if words[2] == "on" or words[2] == "true" then
        strings = "\"'"
      elseif words[2] == "off" or words[2] == "false" then
        strings = false
      else
        strings = strings .. words[2]
      end
    elseif cmd == "operator" and words[2] then
      while words[2] do
        operators[#operators + 1] = table.remove(words, 2)
      end
    end
    return cprefix, strings
  end

  local function match_constant(w, constants, constpat)
    if constants[w] then return true end
    for i=1, #constpat, 1 do
      if w:match(constpat[i]) then
        return true
      end
    end
    return false
  end
  
  local function is_op(op, ops)
    for i=1, #ops, 1 do
      if ops[i] == op then
        return true
      end
    end
  end

  local function mkhighlighter(file)
    do
      return nil
    end
    local numpat, keywords, keychars,
          constpat, functions, constants,
          operators, cprefix, strings =
            {}, {}, {}, {}, {}, {}, {}, "#", "\"'"
    local handle, err = io.open(file, "r")
    if not handle then
      return nil
    end
    for line in handle:lines() do
      cprefix, strings = parse_line(line, numpat, keywords, keychars,
                                    constpat,functions, constants,
                                    operators, cprefix, strings)
    end
    strings = string.format("[%s]", strings)
    handle:close()
    local kchars = ""
    if #keychars > 0 then
      kchars = "[%" .. table.concat(keychars, "%") .. "]"
    end
    local function words(ln)
      local words = {}
      local ws, word, last = "", "", ""
      for char in ln:gmatch(".") do
        last = word:sub(-1)
        if (#kchars > 0 and char:match(kchars)) or char:match("[\"'%s,]") then
          ws = char
          if #word > 0 then words[#words + 1] = word end
          if #ws > 0 then words[#words + 1] = ws end
          word = ""
          ws = ""
        elseif #last > 0 and is_op(last..char, operators) then
          word = ws..char
          if #word > 0 then words[#words + 1] = word end
          if #ws > 0 then words[#words + 1] = ws end
          word = ""
          ws = ""
        elseif (last..char) and is_op(last, operators) and '' then
        else
          word = word .. char
        end
      end
      if #word > 0 then words[#words + 1] = word end
      return words
    end

    local function highlight(line)
      local ret = "\27[39m"
      local in_str = false
      local in_cmt = false
      for i, word in ipairs(words(line)) do
        if strings and word:match(strings) and not in_str and not in_cmt then
          in_str = word
          ret = ret .. str_color .. word
        elseif in_str then
          ret = ret .. word
          if word == in_str then
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
                      (match_constant(word, constants, constpat)
                        and const_color) or
                      (#kchars > 0 and word:match(kchars) and kchar_color) or
                      (is_op(word, operators) and (op_color or kchar_color)) or
                      ""
          ret = ret .. esc .. word .. (esc ~= "" and "\27[39m" or "")
        end
      end
      ret = ret .. "\27[39m"
      return ret
    end

    return highlight
  end

  function syntax.load(file)
    return mkhighlighter(file)
  end
end

return syntax
