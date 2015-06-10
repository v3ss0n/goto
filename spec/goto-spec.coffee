Goto = require '../lib/goto'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "Goto", ->
  activationPromise = null
  workspaceElement  = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('goto')

  describe "when the goto:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(workspaceElement.find('.goto-view')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      #atom.workspaceView.trigger 'goto:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(workspaceElement.find('.goto-view')).toExist()
        #atom.workspaceView.trigger 'goto:toggle'
        #expect(atom.workspaceView.find('.goto')).not.toExist()
