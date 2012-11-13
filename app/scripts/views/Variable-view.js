inventingOnPrinciple.Views.VariableView = Backbone.View.extend({

  template: inventingOnPrinciple.getTemplate('variable'),
  tagName: 'span',
  className: 'varDec',
  events: {
    'click .TKAdjustableNumber > span': 'onMouseDown',
    'mouseup .TKAdjustableNumber': 'onMouseUp'
  },
  onMouseDown: function (e) {
    console.log('onMouseDown', e.target);
  },
  onMouseUp: function (e) {
    console.log('onMouseUp', e.target);
  },
  initTangle: function () {
    var self = this;
    _.each(self.model.get('declarations'), function (dec) {
      var defaults = {};
      defaults[dec.id.name] = dec.init.value;
      if (dec.init.type == 'Literal') {
        window.genTangle('span[data-container=' + dec.id.name + ']', defaults, function () {
          // this[dec.id.name] = dec.init.value;
          self.model.setVar(dec.id.name, this[dec.id.name]);
        });
      }
    });
  },
  render: function () {
    this.$el.html(this.template(this.model.toJSON()));
    return this;
  }

});
