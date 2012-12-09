inventingOnPrinciple.Collections.VariableCollection = Backbone.Collection.extend
  model: inventingOnPrinciple.Models.VariableModel
  toVars: ->
    _.flatten @invoke('toDeclarations')
