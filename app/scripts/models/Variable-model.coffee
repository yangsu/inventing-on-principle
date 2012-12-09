inventingOnPrinciple.Models.VariableModel = Backbone.Model.extend
  idAttribute: 'vid'
  setVar: (key, value) ->
    _.each @get('declarations'), (dec) =>
      if dec.id.name is key and dec.init.value isnt value
        dec.init.value = value
        dec.init.update(value)
        @trigger('change:var')

  toDeclarations: ->
    _.map @get('declarations'), (dec, i) =>
      id: @cid + '-' + i
      name: dec.id.name
      init: dec.init
      loc: dec.loc


  toTemplate: ->
    depth: @get('depth')
    decs: @toDeclarations()
