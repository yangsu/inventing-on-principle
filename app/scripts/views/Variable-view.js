inventingOnPrinciple.Views.VariableView = Backbone.View.extend({

  template: inventingOnPrinciple.getTemplate('variable'),
  events: {
  },
  initTangle: function () {
    var self = this
      , model = this.model;
    _.each(self.model.get('declarations'), function (dec, i) {
      var defaults = {}
        , name = dec.id.name;

      defaults[name] = dec.init.value;
      if (dec.init.type == 'Literal') {
        window.genTangle('span[data-container=' + model.cid + '-' + i + ']', defaults, function () {
          model.setVar(name, this[name]);
        });
      }
    });
  },
  render: function () {
    this.$el.html(this.template(this.model.toDeclarations()));
    return this;
  }

});
