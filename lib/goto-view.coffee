
path = require 'path'
fs = require 'fs'
{$$, SelectListView} = require 'atom-space-pen-views'
utils = require './symbol-utils'

module.exports =
class GotoView extends SelectListView

  initialize: ->
    super
    @addClass('goto-view fuzzy-finder')
    # Use fuzzy-finder styles

    @currentEditor = null
    # If this is non-null, then the command was 'Goto File Symbol' and this is the current file's
    # editor view. Autoscroll to the selected item.

    @cancelPosition = null
    # The original position of the screen and selections so they can be restored if the user
    # cancels. This is only set by the Goto File Symbol command when auto-scrolling is enabled.
    # If set, it is an object containing:
    #  :firstRow - the editor's first visible row
    #  :selections - the original selections

  destroy: ->
    @cancel()
    @panel?.destroy()

  cancel: ->
    super
    @restoreCancelPosition()
    @currentEditor = null
    @cancelPosition = null

  populate: (symbols, editor) ->
    @rememberCancelPosition(editor)
    @setItems(symbols)
    @show()

  rememberCancelPosition: (editor) ->
    if not editor or not atom.config.get('goto.autoScroll')
      return

    @currentEditor = editor
    @cancelPosition =
      position: editor.getCursorBufferPosition()
      selections: editor.getSelectedBufferRanges()

  restoreCancelPosition: ->
    if @currentEditor and @cancelPosition
      @currentEditor.setCursorBufferPosition(@cancelPosition.position)
      if @cancelPosition.selections
        @currentEditor.setSelectedBufferRanges(@cancelPosition.selections)

  forgetCancelPosition: ->
    @currentEditor = null
    @cancelPosition = null

  getFilterKey: -> 'name'

  scrollToItemView: (view) ->
    # Hook the selection of an item so we can scroll the current buffer to the item.
    super
    symbol = @getSelectedItem()
    @onItemSelected(symbol)

  onItemSelected: (symbol) ->
    @currentEditor?.setCursorBufferPosition(symbol.position)

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

    if not fs.existsSync(symbol.path)
      @setError('Selected file does not exist')
      setTimeout((=> @setError()), 2000)
    else if atom.workspace.getActiveTextEditor()
      @cancel()
      utils.gotoSymbol(symbol)

  show: ->
    @storeFocusedElement()
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  hide: ->
    @panel?.hide()

  cancelled: ->
    @hide()
