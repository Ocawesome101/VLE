#!/bin/bash
# make a standalone `vle' Lua script with no external dependencies

set -xe
cat base.lua | head -n 3 > vle
cat lib/iface.lua | head -n -2 >> vle
cat lib/kbd.lua | head -n -2 >> vle
echo "local rc" >> vle
cat lib/vlerc.lua >> vle
cat lib/nsyntax.lua | head -n -2 >> vle
cat base.lua | tail -n $(echo "`wc -l base.lua | cut -d ' ' -f1` - 7" | bc) >> vle
chmod +x vle
