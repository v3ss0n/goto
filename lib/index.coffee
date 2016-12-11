
SymbolIndex = require('./symbol-index')
GotoView = require('./goto-view')

module.exports =

  config:
    logToConsole:
      default: false
      type: 'boolean'
      description: 'Enable debug information logging for goto commands'
    moreIgnoredNames:
      default: ''
      type: 'string'
      description: 'Whitespace- or comma-separated list of globs for files that goto should skip. These files are in addition to those specified in the core.ignoredNames setting'
    autoScroll:
      default: true
      type: 'boolean'
      description: 'Disable this option to prevent goto from restoring your selection back to your original cursor position after cancelling a goto method'

  index: null
  gotoView: null

  activate: (state) ->
    @index = new SymbolIndex(state?.entries)
    @gotoView = new GotoView()
    atom.commands.add 'atom-workspace', {
      'goto:project-symbol': => @gotoProjectSymbol()
      'goto:file-symbol': => @gotoFileSymbol()
      'goto:declaration': => @gotoDeclaration()
      'goto:rebuild-index': => @index.rebuild()
      'goto:invalidate-index': => @index.invalidate()
    }

  deactivate: ->
    @index?.destroy()
    @index = null
    @gotoView?.destroy()
    @gotoView = null

  serialize: -> { entries: @index.entries }

  gotoDeclaration: ->
    symbols = @index.gotoDeclaration()
    if symbols and symbols.length
      @gotoView.populate(symbols)

  gotoProjectSymbol: ->
    symbols = @index.getAllSymbols()
    @gotoView.populate(symbols)

  gotoFileSymbol: ->
    editor = atom.workspace.getActiveTextEditor()
    filePath = editor?.getPath()
    if filePath
      symbols = @index.getEditorSymbols(editor)
      @gotoView.populate(symbols, editor)
