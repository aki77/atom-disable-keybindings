_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'

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

    callback = _.debounce((=> @reload()), 1000)
    @subscriptions.add(atom.config.onDidChange('disable-keybindings', callback))

    atom.packages.onDidActivateInitialPackages( => @reload())

  deactivate: ->
    @subscriptions.dispose()
    @reset()

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
      console.log 'disable keyBinding', binding if atom.devMode
      @removedKeyBindings.add(binding)
    return

  reset: ->
    @removedKeyBindings.forEach((binding) ->
      if atom.keymaps.keyBindings.indexOf(binding) is -1
        console.log 'enable keyBinding', binding if atom.devMode
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
