inventingOnPrinciple.Collections.VariableCollection = Backbone.Collection.extend({

  model: inventingOnPrinciple.Models.VariableModel,

  toVars: function () {
    return _.flatten(this.invoke('toDeclarations'));
  }

});
