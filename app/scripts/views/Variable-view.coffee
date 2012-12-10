inventingOnPrinciple.Views.VariableView = Backbone.View.extend
  template: inventingOnPrinciple.getTemplate('variable')
  tagName: 'span'
  className: 'varDec'

  events:
    mouseup: 'onMouseUp'

  onMouseUp: (e) ->
    @model.trigger 'endChange'

  initTangle: ->
    model = @model

    variable = model.toTemplateContext()
    defaults = {}
    name = variable.name
    defaults[name] = variable.value

    if variable.type is Syntax.Literal
      window.genTangle "span[data-container=#{model.cid}]", defaults, ->
        model.setVar this[name]

  render: ->
    @$el.html @template @model.toTemplateContext()
    this

  renderText: ->
    ctx = @model.toTemplateContext()
    "#{ctx.name} = #{ctx.value}"