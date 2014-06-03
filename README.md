# goto package

Provides "goto symbol" functionality for the current file or the entire project.

This is a replacement for Atom's built-in symbols-view package that uses Atom's own syntax files
to identify symbols rather than ctags.  The ctags project is very useful but it is never going
to keep up with all of the new Atom syntaxes that will be created as Atom grows.

Commands:

* `cmd-r` - Goto File Symbol
* `cmd-shift-r` - Goto Project Symbol
* `cmd-alt-down` - Goto Declaration
* Rebuild Index
* Invalidate Index

## Index

The symbol index is currently maintained in memory.  Goto File Symbol will reindex the current
file if necessary and editing a file will automatically invalidate the symbol cache for it.

Symbols for the entire project are not indexed until the Goto Project Symbol or Goto
Declaration commands are used.

While symbols are automatically kept up to date as buffers are modified, the package  does not
yet watch for external file modifications.  If you change files externally, such as through a
"git pull" or switching branches, you can use run Invalidate Index to clear the current index
so it will be rebuilt when needed or Rebuild Index to rebuild it immediately.

## Options

### More Ignored Names

A whitespace and/or comma separated list of globs (filenames or wildcards) to ignore, applied
to both files and directories.  This can be useful for speeding up the rebuilding of the index.

Example: `node_modules, *.sql`

### Auto Scroll

By default the Goto File Symbol command will scroll the selected command into view.  Pressing
`Esc` to cancel the command restores the position of the screen.  Uncheck this option to
disable the scrolling.

Note that the Goto Project Symbol does not scroll the editor since it displays choices from
multiple files.
