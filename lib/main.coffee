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

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    callback = ({newValue}) => @reload(newValue)
    @subscriptions.add(atom.config.onDidChange('disable-package-keybindings', callback))

    atom.packages.onDidActivateInitialPackages( => @initialize())

  deactivate: ->
    @subscriptions.dispose()

  initialize: ->
    config = atom.config.get('disable-package-keybindings')
    packages = atom.packages.getLoadedPackages()

    return @disableKeymaps(packages) if config.disableAllPackages
    return if config.disablePackages.length == 0

    for pack in packages when config.disablePackages.indexOf(pack.name) > -1
      @disableKeymaps(pack)

    return

  reload: ({disableAllPackages, disablePackages}) ->
    packages = atom.packages.getLoadedPackages()
    @disableKeymaps(packages)
    return if disableAllPackages

    for pack in packages when disablePackages.indexOf(pack.name) < 0
      @addKeymaps(pack)

  addKeymaps: (pack) ->
    if Array.isArray(pack)
      @addKeymaps(p) for p in pack
      return

    for [keymapPath, map] in pack.keymaps
      #console.log "add keymap: #{keymapPath}"
      atom.keymaps.add(keymapPath, map)
    return

  disableKeymaps: (pack) ->
    if Array.isArray(pack)
      @disableKeymaps(p) for p in pack
      return

    for [keymapPath, map] in pack.keymaps
      #console.log "disablekeymap: #{keymapPath}"
      atom.keymaps.removeBindingsFromSource(keymapPath)
    return
