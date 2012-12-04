inventingOnPrinciple.Views.FunctionView = Backbone.View.extend({
  tagName: 'div',
  className: 'funDecs',
  template: inventingOnPrinciple.getTemplate('function'),
  render: function () {
    this.$el.html(this.template(this.model.toJSON()));
    return this;
  }

});
