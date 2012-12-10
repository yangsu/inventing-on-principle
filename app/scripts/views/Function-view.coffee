inventingOnPrinciple.Views.FunctionView = Backbone.View.extend
  tagName: 'div'
  className: 'funDecs'
  template: inventingOnPrinciple.getTemplate('function')
  render: ->
    @$el.html @template(@model.toJSON())
    this
  renderText: ->
    ctx = @model.toJSON()
    params = (param.name for own k, param of ctx.params).join(', ')
    "function #{ctx.id.name} ( #{params} )"
