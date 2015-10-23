{WorkspaceView} = require 'atom'
StarrynightHelper = require '../lib/starrynight-helper'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "StarryNightHelper", ->
  activationPromise = null

  beforeEach ->
    atom.workspaceView = new WorkspaceView
    activationPromise = atom.packages.activatePackage('starrynight-helper')

  describe "when the starrynight-helper:toggle event is triggered", ->
    it "attaches and then detaches the view", ->
      expect(atom.workspaceView.find('.starrynight-helper')).not.toExist()

      # This is an activation event, triggering it will cause the package to be
      # activated.
      atom.workspaceView.trigger 'starrynight-helper:toggle'

      waitsForPromise ->
        activationPromise

      runs ->
        expect(atom.workspaceView.find('.starrynight-helper')).toExist()
        atom.workspaceView.trigger 'starrynight-helper:toggle'
        expect(atom.workspaceView.find('.starrynight-helper')).not.toExist()
