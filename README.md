# VLE - Visual Lua Editor

Not to be confused with Monolith's VLED.

This is a text editor, similar to [TLE](https://github.com/ocawesome101/tle), but modal.

Commands are generally single letters, followed if necessary by arguments.  All commands must be prefixed with a `:`.  Switch between insert and command modes with the `[TAB]` key.  Otherwise mostly use like Vim.

Supports syntax highlighting in exactly the same manner as TLE and VLED.

Available commands:

 - `N`: Jump to line `N`.
 - `bN`: Switch to buffer `N`.
 - `c`: Close buffer
 - `d[N=1]`: Delete `N` lines from the buffer.
 - `n [fname]`: Open a new buffer.
 - `move [+-]N`: Move the current line forward or backward by `N`.
 - `s/PAT/REP/`: Replace all instances of `PAT` with `REP` in the same manner as `string.gsub`.
 - `w [fname]`: Write file
 - `q`: Close editor
 - `wc`: Write file and close buffer
 - `wq`: Write file and close editor
