
fs = require 'fs'
path = require 'path'
_ = require 'underscore'
minimatch = require 'minimatch'
generate = require './symbol-generator'
utils = require './symbol-utils'

module.exports =
class SymbolIndex
  constructor: (entries)->

    @entries = {}
    # The cache of symbols which maps from fully-qualified-name (absolute path) to either an
    # array of symbols or null if the file needs to be rescanned.
    #
    # If the index needs to be rebuilt, it will contain only individual files that have been
    # scanned by the Goto File Symbol command.

    @rescanDirectories = true
    # If true we must rescan the directories to provide all project symbols.
    #
    # The @entries starts out empty and we need to scan the project directories to find all
    # symbols.  Once we've done this once we have all of the filenames and can mark them as
    # invalid when they are modified by setting their @entries value to null.  If something
    # invalidates our list of filenames (e.g. the project path is changed), directories need
    # to be rescanned again.
    #
    # Note that we may have values in @entries even if directories have not been scaned since
    # the Goto File Symbols command will populate it.  We allow this so that individual file
    # symbols can be cached without requiring a full project scan for cases where the Goto
    # Project Symbols command is not used.

    @root = atom.project.getRootDirectory()
    @repo = atom.project.getRepo()
    @ignoredNames = atom.config.get('core.ignoredNames') ? []
    if typeof @ignoredNames is 'string'
      @ignoredNames = [ ignoredNames ]

    @logToConsole = atom.config.get('goto.logToConsole') ? false
    @moreIgnoredNames = atom.config.get('goto.moreIgnoredNames') ? ''
    @moreIgnoredNames = (n for n in @moreIgnoredNames.split(/[, \t]+/) when n?.length)

    @noGrammar = {}
    # File extensions that we've found have no grammar.  There are probably a lot of files
    # such as *.png that we don't have grammars for.  Instead of hardcoding them we'll record
    # them on the fly.  We'll clear this when we rescan directories.

    @subscribe()

  invalidate: ->
    @entries = {}
    @rescanDirectories = true

  subscribe: () ->
    atom.project.on 'path-changed', =>
      @root = atom.project.getRootDirectory()
      @repo = atom.project.getRepo()
      @invalidate()

    atom.config.observe 'core.ignoredNames', =>
      @ignoredNames = atom.config.get('core.ignoredNames') ? []
      if typeof @ignoredNames is 'string'
        @ignoredNames = [ ignoredNames ]
      @invalidate()

    atom.config.observe 'goto.moreIgnoredNames', =>
      @moreIgnoredNames = atom.config.get('goto.moreIgnoredNames') ? ''
      @moreIgnoredNames = (n for n in @moreIgnoredNames.split(/[, \t]+/) when n?.length)
      @invalidate()

    atom.project.eachBuffer (buffer) =>
      # TODO: Do path-changed and reloaded trigger contents-modified?
      buffer.on 'contents-modified', =>
        @entries[buffer.getPath()] = null

      buffer.on 'destroyed', =>
        buffer.off()

    atom.workspace.eachEditor (editor) =>
      editor.on 'grammar-changed', =>
        @entries[editor.getPath()] = null

      editor.on 'destroyed', =>
        editor.off()

  destroy: ->
    @entries = null

  getEditorSymbols: (editor) ->
    # Return the symbols for the given editor, rescanning the file if necessary.
    fqn = editor.getPath()
    if not @entries[fqn] and @keepPath(fqn)
      @entries[fqn] = generate(fqn, editor.getGrammar(), editor.getText())
    return @entries[fqn]

  getAllSymbols: ->
    # Returns the symbols for the entire project.
    @update()

    s = []
    for fqn, symbols of @entries
      Array::push.apply s, symbols
    return s

  update: ->
    if @rescanDirectories
      @rebuild()
    else
      for fqn, symbols of @entries
        if symbols is null and @keepPath(fqn)
          @processFile(fqn)

  rebuild: ->
    if @root
      @processDirectory(@root.path)
    @rescanDirectories = false
    console.log('No Grammar:', Object.keys(@noGrammar)) if @logToConsole

  gotoDeclaration: ->
    e = atom.workspace.getActiveEditor()
    word = e?.getTextInRange(e.getCursor().getCurrentWordBufferRange())
    if not word?.length
      return null

    @update()

    # TODO: I'm quite sure this is not using Coffeescript idioms.  Rewrite.

    filePath = e.getPath()
    matches = []
    @matchSymbol(matches, word, @entries[filePath])
    for fqn, symbols of @entries
      if fqn isnt filePath
        @matchSymbol(matches, word, symbols)

    if matches.length is 0
      return null

    if matches.length > 1
      return matches

    utils.gotoSymbol(matches[0])

  matchSymbol: (matches, word, symbols) ->
    if symbols
      for symbol in symbols
        if symbol.name is word
          matches.push(symbol)

  processDirectory: (dirPath) ->
    if @logToConsole
      console.log('GOTO: directory', dirPath)

    entries = fs.readdirSync(dirPath)

    dirs = []

    for entry in entries
      fqn = path.join(dirPath, entry)
      stats = fs.statSync(fqn)
      if @keepPath(fqn,stats.isFile())
        if stats.isDirectory()
          dirs.push(fqn)
        else if stats.isFile()
          @processFile(fqn)
    entries = null

    for dir in dirs
      @processDirectory(dir)

  processFile: (fqn) ->
    console.log('GOTO: file', fqn) if @logToConsole
    text = fs.readFileSync(fqn, { encoding: 'utf8' })
    grammar = atom.syntax.selectGrammar(fqn, text)
    if grammar?.name isnt "Null Grammar"
      @entries[fqn] = generate(fqn, grammar, text)
    else
      @noGrammar[path.extname(fqn)] = true

  keepPath: (filePath,isFile=true) ->
    # Should we keep this path in @entries?  It is not kept if it is excluded by the
    # core ignoredNames setting or if the associated git repo ignore it.

    base = path.basename(filePath)
    ext = path.extname(base)

    # files with this extensions are known not to have a grammar.
    if isFile and @noGrammar[ext]?
      console.log('GOTO: ignore/grammar', filePath) if @logToConsole
      return false

    for glob in @moreIgnoredNames
      if minimatch(base, glob)
        console.log('GOTO: ignore/core', filePath) if @logToConsole
        return false

    if _.contains(@ignoredNames, base)
      console.log('GOTO: ignore/core', filePath) if @logToConsole
      return false

    if ext and _.contains(@ignoredNames, '*#{ext}')
      console.log('GOTO: ignore/core', filePath) if @logToConsole
      return false

    if @repo and @repo.isPathIgnored(filePath)
      console.log('GOTO: ignore/git', filePath) if @logToConsole
      return false

    return true
