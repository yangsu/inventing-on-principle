inventingOnPrinciple.Models.VariableModel = Backbone.Model.extend
  idAttribute: 'vid'
  setVar: (value) ->
    init = @get('init')
    if init? and init.value isnt value
      init.value = value
      init.updateSource(value)
      @trigger('change:var')

  toTemplateContext: ->
    init = @get('init')

    id: @cid
    depth: @get('depth')
    name: @get('id').name
    loc: @get('loc')
    type: (init and init.type) ? 'undefined'
    node: @toJSON()
    value:
      if init?
        switch init.type
          when Syntax.Identifier then init.name
          when Syntax.Literal then init.value
          else init.source()
      else
        'undefined'
