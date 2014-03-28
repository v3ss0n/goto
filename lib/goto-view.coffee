{View} = require 'atom'

module.exports =
class GotoView extends View
  @content: ->
    @div class: 'goto overlay from-top', =>
      @div "The Goto package is Alive! It's ALIVE!", class: "message"

  initialize: (serializeState) ->
    atom.workspaceView.command "goto:toggle", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "GotoView was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.append(this)
