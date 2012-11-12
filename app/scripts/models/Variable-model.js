inventingOnPrinciple.Models.VariableModel = Backbone.Model.extend({
  initialize: function () {

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
