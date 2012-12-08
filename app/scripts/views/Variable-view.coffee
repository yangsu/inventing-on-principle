inventingOnPrinciple.Views.VariableView = Backbone.View.extend
  template: inventingOnPrinciple.getTemplate('variable')
  tagName: 'div'
  className: 'varDecs'

  events:
    mouseup: 'onMouseUp'

  onMouseUp: (e) ->
    @model.trigger 'endChange'

  initTangle: ->
    model = @model
    _.each model.get('declarations'), (dec, i) =>
      defaults = {}
      name = dec.id.name
      defaults[name] = dec.init.value

      if dec.init.type is 'Literal'
        window.genTangle "span[data-container=#{model.cid}-#{i}]", defaults, ->
          model.setVar name, this[name]

  render: ->
    @$el.html @template(@model.toTemplate())
    this
