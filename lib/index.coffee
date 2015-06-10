
SymbolIndex = require('./symbol-index')
GotoView = require('./goto-view')

module.exports =

  configDefaults:
    logToConsole: false
    moreIgnoredNames: ''
    autoScroll: true

  index: null
  gotoView: null

  activate: (state) ->
    @index = new SymbolIndex(state?.entries)
    @gotoView = new GotoView()
    atom.commands.add 'atom-workspace', {
      'mobile-preview:toggle': => @toggle()
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
