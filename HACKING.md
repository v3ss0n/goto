
# Design

## Goals

I am going to start with a primitive design to get something useful working and improve it over
time as I learn more about Atom's internals and is it gains more features I can take advantage
of.

The current goals are:

* Symbols are based on Atom syntax files
* Project-wide Go To Symbol
* File Go To Symbol
* Project-wide Go To Definition
* Symbols will be kept up to date with modifications made in the editor.
* Symbols for modified files will be accurate
* Requires a git repo and only indexes files that are not ignored
* Also honors the core.ignoredNames settings

These are future goals and will not be handled in the first versions:

* Detect file external file changes such as from a "git pull"
* Caching of symbols between restarts

## Implementation
