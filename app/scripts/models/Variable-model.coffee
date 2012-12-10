inventingOnPrinciple.Models.VariableModel = Backbone.Model.extend
  idAttribute: 'vid'
  setVar: (key, value) ->
    _.each @get('declarations'), (dec) =>
      if dec.id.name is key and dec.init.value isnt value
        dec.init.value = value
        dec.init.updateSource(value)
        @trigger('change:var')

  toDeclarations: ->
    _.map @get('declarations'), (dec, i) =>
      decData =
        id: @cid + '-' + i
        name: dec.id.name
        loc: dec.loc
      if dec.init?
        decData.type = dec.init.type
        decData.init =
          switch dec.init.type
            when Syntax.Identifier then dec.init.name
            when Syntax.Literal
              decData.enableTangle = true
              dec.init.value
            else dec.init.source()
      else
        decData.type = 'undefined'
        decData.init = 'undefined'

      decData

  toTemplate: ->
    depth: @get('depth')
    decs: @toDeclarations()
