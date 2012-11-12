inventingOnPrinciple.Collections.VariableCollection = Backbone.Collection.extend({

  model: inventingOnPrinciple.VariableModel,

  toVars: function () {
    return _.flatten(this.invoke('toDeclarations'));
  }

});
