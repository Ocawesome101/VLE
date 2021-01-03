-- very basic sh highlighting for VLE --

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

local kchars = "[%{%}%[%]%(%)%s\"',%+%=%%%/%|%&%>%<%*%$]"
local function words(ln)
  local words = {}
  local ws, word = "", ""
  for char in ln:gmatch(".") do
    if char:match("[%{%}%[%]%(%)%s\"',%+%=%%%/%|%&%>%<%*%$]") then
      ws = char
      if #word > 0 then words[#words + 1] = word  end
      if #ws > 0 then words[#words + 1] = ws  end
      word = ""
      ws = ""
    else
      word = word .. char
    end
  end
  if #word > 0 then words[#words + 1] = word  end
  if #ws > 0 then words[#words + 1] = ws  end
  return words
end

local function highlight(line)
  local ret = ""
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
    elseif word:sub(1,1) == "#" then
      in_cmt = true
      ret = ret .. cmt_color .. word
    elseif in_cmt then
      ret = ret .. word
    else
      local esc = (word:match(kchars) and kchar_color) or ""
      ret = ret .. esc .. word .. (esc ~= "" and "\27[39m" or "")
    end
  end
  ret = ret .. "\27[39m"
  return ret
end

return highlight
