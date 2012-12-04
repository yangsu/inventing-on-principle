inventingOnPrinciple.Models.ApplicationModel = Backbone.Model.extend({
  markers: [],
  parsingOptions: {
    comment: true,
    loc: true,
    range: true,
    raw: true,
    tokens: true
  },
  initialize: function () {
    this.ast = new inventingOnPrinciple.Models.ASTModel();
  },
  processUpdate: function () {
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
    var parsedResult, ast, generated, vars;
    // if (text == this.ast.toSource()) return;

    if (inventingOnPrinciple.updating) {
      return;
    }

    try {
      this.ast
        .setSource(text)
        .extractVars();

      inventingOnPrinciple.view.runCode();
    } catch (e) {
      // console.log('parse Error', e);
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
