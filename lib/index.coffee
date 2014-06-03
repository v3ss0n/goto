
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
    atom.workspaceView.command "goto:project-symbol", => @gotoProjectSymbol()
    atom.workspaceView.command "goto:file-symbol", => @gotoFileSymbol()
    atom.workspaceView.command "goto:declaration", => @gotoDeclaration()
    atom.workspaceView.command "goto:rebuild-index", => @index.rebuild()
    atom.workspaceView.command "goto:invalidate-index", => @index.invalidate()

  deactivate: ->
    @index?.destroy()
    @index = null
    @gotoView?.destroy()
    @gotoView = null

  serialize: -> { 'entries': @index.entries }

  gotoDeclaration: ->
    symbols = @index.gotoDeclaration()
    if symbols
      @gotoView.populate(symbols)

  gotoProjectSymbol: ->
    symbols = @index.getAllSymbols()
    @gotoView.populate(symbols)

  gotoFileSymbol: ->
    v = atom.workspaceView.getActiveView()
    e = v?.getEditor()
    filePath = e?.getPath()
    if filePath
      symbols = @index.getEditorSymbols(e)
      @gotoView.populate(symbols, v)
