{CompositeDisposable} = require 'atom'

module.exports =
  subscriptions: null

  config:
    removesPackages:
      type: 'array'
      default: []
      items:
        type: 'string'
    removesAllPackages:
      type: 'boolean'
      default: false

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    callback = ({newValue}) => @reload(newValue)
    @subscriptions.add(atom.config.onDidChange('remove-package-keybindings', callback))

    atom.packages.onDidActivateInitialPackages( => @initialize())

  deactivate: ->
    @subscriptions.dispose()

  initialize: ->
    config = atom.config.get('remove-package-keybindings')
    packages = atom.packages.getLoadedPackages()

    return @removeKeymaps(packages) if config.removesAllPackages
    return if config.removesPackages.length == 0

    for pack in packages when config.removesPackages.indexOf(pack.name) > -1
      @removeKeymaps(pack)

    return

  reload: ({removesAllPackages, removesPackages}) ->
    packages = atom.packages.getLoadedPackages()
    @removeKeymaps(packages)
    return if removesAllPackages

    for pack in packages when removesPackages.indexOf(pack.name) < 0
      @addKeymaps(pack)

  addKeymaps: (pack) ->
    if Array.isArray(pack)
      @addKeymaps(p) for p in pack
      return

    for [keymapPath, map] in pack.keymaps
      #console.log "add keymap: #{keymapPath}"
      atom.keymaps.add(keymapPath, map)
    return

  removeKeymaps: (pack) ->
    if Array.isArray(pack)
      @removeKeymaps(p) for p in pack
      return

    for [keymapPath, map] in pack.keymaps
      #console.log "remove keymap: #{keymapPath}"
      atom.keymaps.removeBindingsFromSource(keymapPath)
    return
