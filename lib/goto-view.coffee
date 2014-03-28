
path = require 'path'
fs = require 'fs'
{$$, SelectListView} = require 'atom'
utils = require './symbol-utils'

module.exports =
class GotoView extends SelectListView

  initialize: ->
      super
      @addClass('goto-view overlay from-top')

  destroy: ->
    @cancel()
    @detach()

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.appendToTop(this)
    @focusFilterEditor()

  populate: (symbols) ->
    @setItems(symbols)
    @attach()

  getFilterKey: -> 'name'

  viewForItem: (symbol) ->
    $$ ->
      @li class: 'two-lines', =>
        @div symbol.name, class: 'primary-line'
        dir = path.basename(symbol.path)
        text = "#{dir} #{symbol.position.row + 1}"
        @div text, class: 'secondary-line'

  getEmptyMessage: (itemCount) ->
    if itemCount is 0
      'No symbols found'
    else
      super

  confirmed: (symbol) ->
    if not fs.existsSync(atom.project.resolve(symbol.path))
      @setError('Selected file does not exist')
      setTimeout((=> @setError()), 2000)
    else
      @cancel()
      utils.gotoSymbol(symbol)
