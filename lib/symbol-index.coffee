
path = require 'path'
_ = require 'underscore'

module.exports =
class SymbolIndex
  constructor: ->
    @entries = {}
    # maps from path to a symbols array

  destroy: ->
    @entries = {} # free up memory

  rebuild: ->
    @entries = {}

    repo = atom.project.getRepo()
    if not repo
      return

    ignoredNames = atom.config.get('core.ignoredNames') ? []
    if typeof ignoredNames is 'string'
      ignoredNames = [ ignoredNames ]

    root = atom.project.getRootDirectory()

    console.log('rebuild: repo=', repo, 'ignoredNames=', ignoredNames, 'root=', root)
    @processDirectory(root, repo, ignoredNames)

    console.log('complete:', @entries)

  processDirectory: (dir, repo, ignoredNames) ->
    entries = (e for e in dir.getEntriesSync() when @keepPath(e.path, repo, ignoredNames))

    for e in entries
      if e.contains? # is a directory
        @processDirectory(e, repo, ignoredNames)
      else
        @entries[e.getPath()] = []

  keepPath: (filePath, repo, ignoredNames) ->
    if repo.isPathIgnored(filePath)
      return false

    if _.contains(ignoredNames, path.basename(filePath))
      return false

    ext = path.extname(filePath)
    if ext and _.contains(ignoredNames, '*#{ext}')
      return false

    return true
