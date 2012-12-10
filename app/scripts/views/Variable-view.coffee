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

    _.each model.toDeclarations(), (dec, i) =>
      defaults = {}
      name = dec.name
      defaults[name] = dec.init
      if dec.enableTangle
        window.genTangle "span[data-container=#{model.cid}-#{i}]", defaults, ->
          model.setVar name, this[name]

  render: ->
    @$el.html @template(@model.toTemplate())
    this
