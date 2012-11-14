inventingOnPrinciple.Models.VariableModel = Backbone.Model.extend({
  setVar: function (key, value) {
    var self = this;

    _.each(this.get('declarations'), function (dec) {
      if (dec.id.name == key) {
        dec.init.value = value;
        // self.trigger('change');
        var from = window.util.convertLoc(dec.init.loc.start);
        var to = window.util.convertLoc(dec.init.loc.end);

        var token = inventingOnPrinciple.codeEditor.getTokenAt(to);
        var start = inventingOnPrinciple.codeEditor.posFromIndex(token.start);
        var end = inventingOnPrinciple.codeEditor.posFromIndex(token.end);

        inventingOnPrinciple.updating = true;
        inventingOnPrinciple.codeEditor.replaceRange(value + "", start, end);
        inventingOnPrinciple.updating = false;
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
