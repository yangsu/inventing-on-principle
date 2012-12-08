inventingOnPrinciple.Views.FunctionView = Backbone.View.extend
  tagName: 'div'
  className: 'funDecs'
  template: inventingOnPrinciple.getTemplate('function')
  render: ->
    @$el.html @template(@model.toJSON())
    this
