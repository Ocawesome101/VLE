# VLE - Visual Lua Editor

Not to be confused with Monolith's VLED.

This is a text editor, similar to [TLE](https://github.com/ocawesome101/tle), but modal.

To run `standalone.sh` on Mac OS you'll need to install GNU coreutils because there are some dependencies on GNU-specific behavior.

Commands are generally single letters, followed if necessary by arguments.  All commands must be prefixed with a `:`.  Switch between insert and command modes with the `[TAB]` key.  Otherwise mostly use like Vim.

Supports syntax highlighting - see **Highlighting** below.

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

## Highlighting

Syntax highlighting for VLE is much simpler than that of its predecessors, accomplished through the use of `syntax/LANG.vle` files. These files contain lines that are evaluated by a simple parser when the appropriate file is loaded.

For an example syntax file, see `syntax/lua.vle` in this repository.

This parser checks the first word of every line for the following words, and acts on the remaining ones accordingly:

 - `keychars`: Adds characters to be highlighted blue.  Note that these tell the syntax highlighter where to "split" words, so keychars that appear in the middle of keywords should not be added here.  Can feature multiple characters per word, or all characters in one word, or a mix of the two.
 - `comment`: Sets the comment prefix character.  If unset, defaults to `#`.
 - `keywords`: Adds keywords (i.e. `if`, `while`).  Differently highlighted from builtins.
 - `const`: Sets keywords to be highlighted as constants (i.e. `true`, `false`).
 - `builtin`: Adds language builtins (i.e. `print`, `tostring`).  Should be used to highlight functions.
 - `constpat`: Adds a pattern against which words will be checked to see if they are constants.  Useful in cases such as Lua's `goto`, where `goto` targets must be dynamically matched.  Also useful for numbers.
 - `strings [on|off|true|false]`: Sets whether the parser should highlight strings.

If you have any questions, or you discover a bug, poke me at `i develop things#5343` on Discord.  I also usually hang out on EsperNet IRC, in `#oc`, as Ocawesome101.
