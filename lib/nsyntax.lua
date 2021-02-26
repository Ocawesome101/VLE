-- rewritten syntax highlighting engine

local syntax = {}

do
  local function esc(n)
    return string.format("\27[%dm", n)
  end
  
  local colors = {
    keyword = esc(rc.keyword or 91),
    builtin = esc(rc.builtin or 92),
    constant = esc(rc.constant or 95),
    string = esc(rc.string or 93),
    comment = esc(rc.comment or 90),
    keychar = esc(rc.keychar or 94),
    operator = esc(rc.operator or rc.keychar or 94)
  }
  
  local function split(l)
    local w = {}
    for wd in l:gmatch("[^ ]+") do
      w[#w+1]=wd
    end
    return w
  end
  
  local function parse_line(self, line)
    local words = split(line)
    local cmd = words[1]
    if not cmd then
      return
    elseif cmd == "keychars" then
      for i=2, #words, 1 do
        self.keychars = self.keychars .. words[i]
      end
    elseif cmd == "comment" then
      self.comment = words[2] or "#"
    elseif cmd == "keywords" then
      for i=2, #words, 1 do
        self.keywords[words[i]] = true
      end
    elseif cmd == "const" then
      for i=2, #words, 1 do
        self.constants[words[i]] = true
      end
    elseif cmd == "constpat" then
      for i=2, #words, 1 do
        self.constpat[#self.constpat+1] = words[i]
      end
    elseif cmd == "builtin" then
      for i=2, #words, 1 do
        self.builtins[words[i]] = true
      end
    elseif cmd == "operator" then
      for i=2, #words, 1 do
        self.operators[words[i]] = true
      end
    elseif cmd == "strings" then
      if words[2] == "on" then
        self.strings = "\"'"
      elseif words[2] == "off" then
        self.strings = false
      else
        self.strings = self.strings .. (words[2] or "")
      end
    end
  end
  
  -- splits on keychars and spaces
  -- groups together blocks of identical keychars
  local function asplit(self, line)
    local words = {}
    local cword = ""
    local opchars = ""
    --for k in pairs(self.operators) do
    --  opchars = opchars .. k
    --end
    --opchars = "["..opchars:gsub("[%[%]%(%)%.%+%%%$%-%?%^%*]","%%%1").."]"
    for char in line:gmatch(".") do
      local last = cword:sub(-1) or ""
      if char:match(self.keychars) then
        if last == char then -- repeated keychar
          cword = cword .. char
        else -- time to split!
          if #cword > 0 then words[#words+1] = cword end
          cword = char
        end
      elseif last:match(self.keychars) then -- also time to split
        if #cword > 0 then words[#words+1] = cword end
        if char == " " then
          words[#words+1]=char
          cword = ""
        else
          cword = char
        end
      elseif self.operators[last .. char] then
        if #cword > 0 then words[#words + 1] = cword:sub(1,-2) end
        words[#words+1] = last..char
        cword = ""
      elseif char:match(self.strings) then
        if #cword > 0 then words[#words+1] = cword end
        words[#words+1] = char
        cword = ""
      elseif char == " " then
        if #cword > 0 then words[#words+1] = cword end
        words[#words+1] = " "
        cword = ""
      else
        cword = cword .. char
      end
    end
    
    if #cword > 0 then
      words[#words+1] = cword
    end
    
    return words
  end
  
  local function isconst(self, word)
    if self.constants[word] then return true end
    for i=1, #self.constpat, 1 do
      if word:match(self.constpat[i]) then
        return true
      end
    end
    return false
  end
  
  local function isop(self, word)
    return self.operators[word]
    --[[for i=1, #self.operators, 1 do
      if self.operators[i] == word then
        return true
      end
    end
    return false]]
  end
  
  local function iskeychar(self, word)
    return not not word:match(self.keychars)
  end
  
  local function highlight(self, line)
    local ret = ""
    local strings, comment = self.strings, self.comment
    local words = asplit(self, line)
    local in_str, in_cmt
    for i, word in ipairs(words) do
      if strings and word:match(strings) and not in_str and not in_cmt then
        in_str = word:sub(1,1)
        ret = ret .. colors.string .. word
      elseif in_str then
        ret = ret .. word
        if word == in_str then
          ret = ret .. "\27[39m"
          in_str = false
        end
      elseif word:sub(1,#comment) == comment then
        in_cmt = true
        ret = ret .. colors.comment .. word
      elseif in_cmt then
        ret = ret .. word
      else
        local esc = (self.keywords[word] and colors.keyword) or
                    (self.builtins[word] and colors.builtin) or
                    (isconst(self, word) and colors.constant) or
                    (isop(self, word) and colors.operator) or
                    (iskeychar(self, word) and colors.keychar) or
                    ""
        ret = string.format("%s%s%s%s", ret, esc, word,
          (esc~=""and"\27[39m"or""))
      end
    end
    ret = ret .. "\27[39m"
    return ret
  end
  
  function syntax.load(file)
    local new = {
      keywords = {},
      operators = {},
      constants = {},
      constpat = {},
      builtins = {},
      keychars = "",
      comment = "#",
      strings = "\"'",
      highlighter = highlight
    }
    local handle = assert(io.open(file, "r"))
    for line in handle:lines() do
      parse_line(new, line)
    end
    new.strings = string.format("[%s]", new.strings)
    new.keychars = string.format("[%s]", (new.keychars:gsub(
      "[%[%]%(%)%.%+%%%$%-%?%^%*]", "%%%1")))
    return function(line)
      return new:highlighter(line)
    end
  end
end

return syntax
