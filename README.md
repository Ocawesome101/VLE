# VLE - Visual Lua Editor

Not to be confused with Monolith's VLED.

This is a text editor, similar to [TLE](https://github.com/ocawesome101/tle), but modal.

Commands are generally single letters, followed if necessary by arguments.  All commands must be prefixed with a `:`.  Switch between insert and command modes with the `[TAB]` key.

Available commands:

 - `n [fname]`: Open a new buffer.
 - `s/PAT/REP/`: Replace all instances of `PAT` with `REP` in the same manner as `string.gsub`.
 - `bN`: Switch to buffer `N`.
 - `c`: Close buffer
 - `w [fname]`: Write file
 - `wq`: Write file and close editor
 - `wc`: Write file and close buffer
 - `q`: Close editor
