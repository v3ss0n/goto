
path = require 'path'
fs = require 'fs'
{$$, SelectListView} = require 'atom'
utils = require './symbol-utils'

module.exports =
class GotoView extends SelectListView

  initialize: ->
    super
    @addClass('goto-view overlay from-top')

    @currentView = null
    # If this is non-null, then the command was 'Goto File Symbol' and this is the current file's
    # editor view.  Autoscroll to the selected item.

    @cancelPosition = null
    # The original position of the screen and selections so they can be restored if the user
    # cancels.  This is only set by the Goto File Symbol command when auto-scrolling is enabled.
    # If set, it is an object containing:
    #  :firstRow - the editor's first visible row
    #  :selections - the original selections

  destroy: ->
    @cancel()
    @detach()

  cancel: ->
    super
    @restoreCancelPosition()
    @currentView = null
    @cancelPosition = null

  attach: ->
    @storeFocusedElement()
    atom.workspaceView.appendToTop(this)
    @focusFilterEditor()

  populate: (symbols, view) ->
    @rememberCancelPosition(view)
    @setItems(symbols)
    @attach()

  rememberCancelPosition: (view) ->
    if not view or not atom.config.get('goto.autoScroll')
      return

    @currentView = view
    @cancelPosition =
      top: view.scrollTop()
      selections: view.getEditor().getSelectedBufferRanges()

  restoreCancelPosition: ->
    if @currentView and @cancelPosition
      @currentView.getEditor().setSelectedBufferRanges(@cancelPosition.selections)
      @currentView.scrollTop(@cancelPosition.top)

  forgetCancelPosition: ->
    @currentView = null
    @cancelPosition = null

  getFilterKey: -> 'name'

  scrollToItemView: (view) ->
    # Hook the selection of an item so we can scroll the current buffer to the item.
    super
    symbol = @getSelectedItem()
    @onItemSelected(view, symbol)

  onItemSelected: (view, symbol) ->
    if @currentView
      editor = @currentView.getEditor()
      @currentView.scrollToBufferPosition(symbol.position, center: true)
      editor.setCursorBufferPosition(symbol.position)
      editor.moveCursorToFirstCharacterOfLine()

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
    @forgetCancelPosition()

    if not fs.existsSync(atom.project.resolve(symbol.path))
      @setError('Selected file does not exist')
      setTimeout((=> @setError()), 2000)
    else
      @cancel()
      utils.gotoSymbol(symbol)
