inventingOnPrinciple.Models.VariableModel = Backbone.Model.extend({
  setVar: function (key, value) {
    var self = this;
    function convert(loc) {
      return {
        line: loc.line,
        ch:   loc.column- 2
      };
    }

    _.each(this.get('declarations'), function (dec) {
      if (dec.id.name == key) {
        dec.init.value = value;
        // self.trigger('change');
        var from = convert(dec.loc.start);
        var to = convert(dec.loc.end);
        var from1 = convert(dec.init.loc.start);
        var to1 = convert(dec.init.loc.end);

        inventingOnPrinciple.updating = true;
        // inventingOnPrinciple.codeEditor.replaceRange(value + "", from, to);
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
