inventingOnPrinciple.Models.VariableModel = Backbone.Model.extend({
  setVar: function (key, value) {
    var self = this;
    _.each(this.get('declarations'), function (dec) {

      if (dec.id.name == key && dec.init.value != value) {
        dec.init.value = value;
        dec.init.update(value);
        self.trigger('change');
      }
    });
  },
  toDeclarations: function () {
    return _.map(this.get('declarations'), function (dec) {
      return {
        name: dec.id.name,
        init: dec.init
      };
    });
  }
});
