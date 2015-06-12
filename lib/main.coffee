_ = require 'underscore-plus'
{CompositeDisposable, Disposable} = require 'atom'

module.exports =
  subscriptions: null

  config:
    disablePackages:
      type: 'array'
      default: []
      items:
        type: 'string'
    disableAllPackages:
      type: 'boolean'
      default: false
    disablePrefixKeys:
      type: 'array'
      default: []
      items:
        type: 'string'

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @removedKeyBindings = new Set

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
      console.log 'activateResources', pack if atom.inDevMode()
      @debouncedReload()

  reload: ->
    config = atom.config.get('disable-keybindings')
    packages = atom.packages.getLoadedPackages()

    @reset()
    oldKeyBindings = atom.keymaps.keyBindings.slice()

    if config.disableAllPackages
      @removeKeymapsFromPackage(packages)
    else if config.disablePackages.length > 0
      for pack in packages when config.disablePackages.indexOf(pack.name) > -1
        @removeKeymapsFromPackage(pack)

    if config.disablePrefixKeys.length > 0
      @removeKeymapsByPrefixKey(config.disablePrefixKeys)

    for binding in _.difference(oldKeyBindings, atom.keymaps.keyBindings)
      console.log 'disable keyBinding', binding if atom.inDevMode()
      @removedKeyBindings.add(binding)
    return

  reset: ->
    @removedKeyBindings.forEach((binding) ->
      if atom.keymaps.keyBindings.indexOf(binding) is -1
        console.log 'enable keyBinding', binding if atom.inDevMode()
        atom.keymaps.keyBindings.push(binding)
    )
    @removedKeyBindings.clear()

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
