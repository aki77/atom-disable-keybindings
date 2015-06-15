_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'

module.exports =
  subscriptions: null

  config:
    allBundledPackages:
      order: 1
      type: 'boolean'
      default: false

    bundledPackages:
      order: 2
      type: 'array'
      default: []
      items:
        type: 'string'

    exceptBundledPackages:
      order: 3
      type: 'array'
      default: []
      items:
        type: 'string'

    allCommunityPackages:
      order: 11
      type: 'boolean'
      default: false

    communityPackages:
      order: 12
      type: 'array'
      default: []
      items:
        type: 'string'

    exceptCommunityPackages:
      order: 13
      type: 'array'
      default: []
      items:
        type: 'string'

    prefixKeys:
      order: 21
      type: 'array'
      default: []
      items:
        type: 'string'

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @removedKeyBindings = new Set
    @debug = atom.inDevMode() and not atom.inSpecMode()

    @debouncedReload = _.debounce((=> @reload()), 1000)
    @subscriptions.add(atom.config.onDidChange('disable-keybindings', @debouncedReload))

    @subscriptions.add(atom.packages.onDidActivateInitialPackages( => @init()))

    @subscriptions.add(atom.commands.add('atom-workspace', 'disable-keybindings:reload', =>
      @reload()
    ))

  deactivate: ->
    @subscriptions.dispose()
    @reset()

  init: ->
    @reload()
    @subscriptions.add(atom.packages.onDidLoadPackage((pack) => @onLoadedPackage(pack)))

  # need update-package
  onLoadedPackage: (pack) ->
    return @debouncedReload() if pack.settingsActivated

    activateResources = pack.activateResources
    pack.activateResources = =>
      activateResources.call(pack)
      pack.activateResources = activateResources
      console.log 'activateResources', pack if @debug
      @debouncedReload()

  reload: ->
    packages = atom.packages.getLoadedPackages()

    @reset()
    oldKeyBindings = atom.keymaps.keyBindings.slice()

    @disablePackageKeymaps()
    @removeKeymapsByPrefixKey(atom.config.get('disable-keybindings.prefixKeys'))

    for binding in _.difference(oldKeyBindings, atom.keymaps.keyBindings)
      console.log 'disable keyBinding', binding if @debug
      @removedKeyBindings.add(binding)
    return

  reset: ->
    @removedKeyBindings.forEach((binding) ->
      if binding not in atom.keymaps.keyBindings
        console.log 'enable keyBinding', binding if @debug
        atom.keymaps.keyBindings.push(binding)
    )
    @removedKeyBindings.clear()

  disablePackageKeymaps: ->
    packages = atom.packages.getLoadedPackages().filter((pack) =>
      @isDisablePackage(pack.name)
    )
    @removeKeymapsFromPackage(packages)

  isDisablePackage: (name) ->
    if atom.packages.isBundledPackage(name)
      return false if name in atom.config.get('disable-keybindings.exceptBundledPackages')
      return true if atom.config.get('disable-keybindings.allBundledPackages')
      return name in atom.config.get('disable-keybindings.bundledPackages')
    else
      return false if name in atom.config.get('disable-keybindings.exceptCommunityPackages')
      return true if atom.config.get('disable-keybindings.allCommunityPackages')
      return name in atom.config.get('disable-keybindings.communityPackages')

  removeKeymapsFromPackage: (pack) ->
    if Array.isArray(pack)
      @removeKeymapsFromPackage(p) for p in pack
      return

    for [keymapPath, map] in pack.keymaps
      atom.keymaps.removeBindingsFromSource(keymapPath)
    return

  removeKeymapsByPrefixKey: (prefixKey) ->
    if Array.isArray(prefixKey)
      @removeKeymapsByPrefixKey(k) for k in prefixKey
      return

    keystrokesWithSpace = prefixKey + ' '
    atom.keymaps.keyBindings = atom.keymaps.keyBindings.filter((binding) ->
      binding.keystrokes.indexOf(keystrokesWithSpace) isnt 0
    )
