#!/bin/bash
# make a standalone `vle' Lua script with no external dependencies

cat base.lua | head -n 3 > vle
cat term/iface.lua | head -n -2 >> vle
cat term/kbd.lua | head -n -2 >> vle
cat base.lua | tail -n $(echo "`wc -l base.lua | cut -d ' ' -f1` - 5" | bc) >> vle
chmod +x vle
