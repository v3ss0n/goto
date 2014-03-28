
SymbolIndex = require('./symbol-index')

module.exports =
  gotoView: null

  index: new SymbolIndex()

  activate: (state) ->
    atom.workspaceView.command "goto:rebuild", => @rebuild()

  deactivate: ->
    @index.destroy()
    @gotoView?.destroy()

  serialize: ->
    # gotoViewState: @gotoView.serialize()

  rebuild: ->
    @index.rebuild()
