inventingOnPrinciple.Views.VariableView = Backbone.View.extend({

  template: inventingOnPrinciple.getTemplate('variable'),
  events: {
  },
  initTangle: function () {
    var self = this
      , model = this.model;
    _.each(self.model.get('declarations'), function (dec) {
      var defaults = {}
        , name = dec.id.name;

      defaults[name] = dec.init.value;
      if (dec.init.type == 'Literal') {
        window.genTangle('span[data-container=' + name + ']', defaults, function () {
          model.setVar(name, this[name]);
        });
      }
    });
  },
  render: function () {
    // this.$el.html(this.template(this.model.toDeclarations()));
    inventingOnPrinciple.state.setValue('');
    var loc
      , str = _.map(this.model.toDeclarations(), function (dec) {
        loc = loc || dec.loc.start;
        var str = dec.name + ': ';
        if (dec.init.type == 'Identifier') {
          str += dec.init.name;
        } else if (dec.init.type == 'Literal') {
          str += dec.init.value;
        }
        return str;
      }).join(', ');
    inventingOnPrinciple.state.replaceRange(str, loc);
    return this;
  }

});
