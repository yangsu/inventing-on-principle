GLOBAL = exports ? this

GLOBAL.genTangle = (selector, defaults, update) ->
  tangle = new Tangle( $(selector).get(0),
    initialize: ->
      _.each defaults, (value, key) =>
        @[key] = value
    update: update
  )
  tangle