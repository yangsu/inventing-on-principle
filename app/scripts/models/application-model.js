inventingOnPrinciple.Models.ApplicationModel = Backbone.Model.extend({
  markers: [],
  initialize: function () {
    this.ast = new inventingOnPrinciple.Models.ASTModel();
  },
  clearMarkers: function () {
    _.invoke(this.markers, 'clear');
    this.markers = [];
  },
  trackCursor: function (editor) {
    var self = this
      , pos = editor.indexFromPos(editor.getCursor())
      , code = editor.getValue()
      , ast = self.ast
      , node, id;

    self.clearMarkers();

    if (ast === null) {
      return;
    }

    ast.pretraverse(function (node) {
      if (
        node.type === esprima.Syntax.Identifier &&
        util.withinRange(pos, node.range)
      ) {
        self.markers.push(editor.markText(
          util.convertLoc(node.loc.start),
          util.convertLoc(node.loc.end),
          'identifier'
        ));
        id = node;
      }
    });

    if (!_.isUndefined(id)) {
      ast.pretraverse(function (node) {
        if (
          node.type === esprima.Syntax.Identifier &&
          node !== id && node.name === id.name
        ) {
          self.markers.push(editor.markText(
            util.convertLoc(node.loc.start),
            util.convertLoc(node.loc.end),
            'highlight'
          ));
        }
      });
    }
  },
  parse: function (text, editor) {
    // if (text == this.ast.toSource()) return;

    if (inventingOnPrinciple.updating) {
      return;
    }

    try {
      this.ast
        .setSource(text)
        .extractDeclarations();
      try {
        this.ast
          .instrumentFunctions();
      } catch (e) {
        console.log(e.name + ": " + e.message);
        console.log(e.toString());
      }
    } catch (e) {
      console.log(e);
      console.trace(e);
      this.trigger('error', e);
    }
  },
  tokens: function () {
    return JSON.stringify(this.ast.get('tokens'), util.adjustRegexLiteral, 4);
  },
  generatedCode: function () {
    return this.ast.get('generatedCode');
  },
  text: function () {
    return this.ast.toSource();
  }
});
