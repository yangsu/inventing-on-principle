inventingOnPrinciple.Views.VariableView = Backbone.View.extend({

  template: inventingOnPrinciple.getTemplate('variable'),
  events: {

  },
  render: function () {
    this.$el.html(this.template(this.model.toJSON()));
    return this;
  }

});
