inventingOnPrinciple.Models.VariableModel = Backbone.Model.extend({
  idAttribute: 'vid',
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
    var self = this;
    return _.map(this.get('declarations'), function (dec, i) {
      return {
        id: self.cid + '-' + i,
        name: dec.id.name,
        init: dec.init,
        loc: dec.loc
      };
    });
  },
  toTemplate: function () {
    return {
      depth: this.get('depth'),
      decs: this.toDeclarations()
    };
  }
});
