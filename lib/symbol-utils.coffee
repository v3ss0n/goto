
module.exports.gotoSymbol = (symbol) ->
    atom.workspaceView.open(symbol.path).done =>
      moveToPosition(symbol.position)

moveToPosition = (position) ->
    editorView = atom.workspaceView.getActiveView()
    if editor = editorView.getEditor?()
      editorView.scrollToBufferPosition(position, center: true)
      editor.setCursorBufferPosition(position)
      editor.moveCursorToFirstCharacterOfLine()
