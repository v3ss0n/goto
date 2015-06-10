
module.exports.gotoSymbol = (symbol) ->
  editor = atom.workspace.getActiveTextEditor()
  if editor and symbol.path != editor.getPath()
    atom.workspace.open(symbol.path).done ->
      moveToPosition(symbol.position)
  else
    moveToPosition(symbol.position)

moveToPosition = (position) ->
  if editor = atom.workspace.getActiveTextEditor()
    editor.setCursorBufferPosition(position)
    editor.moveToFirstCharacterOfLine()
