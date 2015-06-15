path = require 'path'
# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "DisableKeybindings", ->
  [workspaceElement, activationPromise, disableKeybindings] = []

  packageFilter = (name, binding) ->
    keymaps = atom.packages.getLoadedPackage(name).keymaps
    for [keymapPath] in keymaps
      return true if binding.source is keymapPath
    false

  prefixKeyFilter = (prefixKey, binding) ->
    keystrokesWithSpace = prefixKey + ' '
    binding.keystrokes.indexOf(keystrokesWithSpace) is 0

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    activationPromise = atom.packages.activatePackage('disable-keybindings').then((pack) ->
      disableKeybindings = pack.mainModule
    )

    atom.config.set('disable-keybindings.bundledPackages', [])
    atom.config.set('disable-keybindings.bundledAllPackages', false)
    atom.config.set('disable-keybindings.exceptBundledPackages', [])
    atom.config.set('disable-keybindings.communityPackages', [])
    atom.config.set('disable-keybindings.communityAllPackages', false)
    atom.config.set('disable-keybindings.exceptCommunityPackages', [])
    atom.config.set('disable-keybindings.prefixKeys', [])

    waitsForPromise ->
      atom.packages.activatePackage('bracket-matcher')

    waitsForPromise ->
      atom.packages.activatePackage(path.join(__dirname, 'fixtures', 'packages', 'package-with-keymaps1'))

    waitsForPromise ->
      atom.packages.activatePackage(path.join(__dirname, 'fixtures', 'packages', 'package-with-keymaps2'))

    runs ->
      atom.packages.loadPackage('go-to-line').activateResources()

  describe "activate", ->
    it "bundledPackages", ->
      goToLinebindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'go-to-line'))
      bracketMatcherbindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'bracket-matcher'))
      expect(goToLinebindings.length).toBeGreaterThan 0
      expect(bracketMatcherbindings.length).toBeGreaterThan 0
      atom.config.set('disable-keybindings.bundledPackages', ['go-to-line'])

      waitsForPromise ->
        activationPromise

      runs ->
        disableKeybindings.init()
        goToLinebindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'go-to-line'))
        bracketMatcherbindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'bracket-matcher'))
        expect(goToLinebindings.length).toBe 0
        expect(bracketMatcherbindings.length).toBeGreaterThan 0

    it "allBundledPackages", ->
      goToLinebindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'go-to-line'))
      bracketMatcherbindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'bracket-matcher'))
      expect(goToLinebindings.length).toBeGreaterThan 0
      expect(bracketMatcherbindings.length).toBeGreaterThan 0
      atom.config.set('disable-keybindings.allBundledPackages', true)

      waitsForPromise ->
        activationPromise

      runs ->
        disableKeybindings.init()
        goToLinebindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'go-to-line'))
        bracketMatcherbindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'bracket-matcher'))
        expect(goToLinebindings.length).toBe 0
        expect(bracketMatcherbindings.length).toBe 0

    it "exceptBundledPackages", ->
      goToLinebindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'go-to-line'))
      bracketMatcherbindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'bracket-matcher'))
      expect(goToLinebindings.length).toBeGreaterThan 0
      expect(bracketMatcherbindings.length).toBeGreaterThan 0
      atom.config.set('disable-keybindings.allBundledPackages', true)
      atom.config.set('disable-keybindings.exceptBundledPackages', ['bracket-matcher'])

      waitsForPromise ->
        activationPromise

      runs ->
        disableKeybindings.init()
        goToLinebindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'go-to-line'))
        bracketMatcherbindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'bracket-matcher'))
        expect(goToLinebindings.length).toBe 0
        expect(bracketMatcherbindings.length).toBeGreaterThan 0

    it "communityPackages", ->
      package1Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps1'))
      package2Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps2'))
      expect(package1Bindings.length).toBeGreaterThan 0
      expect(package2Bindings.length).toBeGreaterThan 0
      atom.config.set('disable-keybindings.communityPackages', ['package-with-keymaps1'])

      waitsForPromise ->
        activationPromise

      runs ->
        disableKeybindings.init()
        package1Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps1'))
        package2Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps2'))
        expect(package1Bindings.length).toBe 0
        expect(package2Bindings.length).toBeGreaterThan 0

    it "allCommunityPackages", ->
      package1Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps1'))
      package2Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps2'))
      expect(package1Bindings.length).toBeGreaterThan 0
      expect(package2Bindings.length).toBeGreaterThan 0
      atom.config.set('disable-keybindings.allCommunityPackages', true)

      waitsForPromise ->
        activationPromise

      runs ->
        disableKeybindings.init()
        package1Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps1'))
        package2Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps2'))
        expect(package1Bindings.length).toBe 0
        expect(package2Bindings.length).toBe 0

    it "exceptCommunityPackages", ->
      package1Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps1'))
      package2Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps2'))
      expect(package1Bindings.length).toBeGreaterThan 0
      expect(package2Bindings.length).toBeGreaterThan 0
      atom.config.set('disable-keybindings.allCommunityPackages', true)
      atom.config.set('disable-keybindings.exceptCommunityPackages', ['package-with-keymaps2'])

      waitsForPromise ->
        activationPromise

      runs ->
        disableKeybindings.init()
        package1Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps1'))
        package2Bindings = atom.keymaps.getKeyBindings().filter(packageFilter.bind(null, 'package-with-keymaps2'))
        expect(package1Bindings.length).toBe 0
        expect(package2Bindings.length).toBeGreaterThan 0

    it "prefixKeys", ->
      prefixKeyBindings = atom.keymaps.getKeyBindings().filter(prefixKeyFilter.bind(null, 'ctrl-k'))
      expect(prefixKeyBindings.length).toBeGreaterThan 0
      atom.config.set('disable-keybindings.prefixKeys', ['ctrl-k'])

      waitsForPromise ->
        activationPromise

      runs ->
        disableKeybindings.init()
        prefixKeyBindings = atom.keymaps.getKeyBindings().filter(prefixKeyFilter.bind(null, 'ctrl-k'))
        expect(prefixKeyBindings.length).toBe 0
