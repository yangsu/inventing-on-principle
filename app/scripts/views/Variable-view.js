inventingOnPrinciple.Views.VariableView = Backbone.View.extend({

  template: inventingOnPrinciple.getTemplate('variable'),
  events: {
    'click .TKAdjustableNumber > span': 'onMouseDown',
    'mouseup .num': 'onMouseUp'
  },
  onMouseDown: function (e) {
    console.log('onMouseDown', e.target);
  },
  onMouseUp: function (e) {
    var $e = $(e.currentTarget).find('.TKAdjustableNumber')
      , v = $e.attr('data-var')
      , value = $e.children('span').html();
    // this.model.setVar(v, value);
  },
  initTangle: function () {
    var self = this;
    _.each(self.model.get('declarations'), function (dec) {
      var defaults = {}
        , name = dec.id.name;

      defaults[name] = dec.init.value;
      if (dec.init.type == 'Literal') {
        window.genTangle('span[data-container=' + name + ']', defaults, function () {
          // this[name] = dec.init.value;
          inventingOnPrinciple.model.setVar(name, this[name]);
        });
      }
    });
  },
  render: function () {
    this.$el.html(this.template(this.model.toJSON()));
    return this;
  }

});
