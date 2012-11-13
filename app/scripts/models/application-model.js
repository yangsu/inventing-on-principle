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
    var col = new inventingOnPrinciple.Collections.VariableCollection;
    col.on('change', this.processUpdate, this);
    this.set('vars', col);
  },
  processUpdate: function () {
    debugger;
  },
  extractVars: function (ast) {
    var self = this;
    if (_.isArray(ast)) {
      _.each(ast, function (item) {
        self.extractVars(item);
      })
    } else if (_.isObject(ast)) {
      if (ast.type == 'VariableDeclaration') {
        self.get('vars').add(new inventingOnPrinciple.Models.VariableModel(ast), { silent: true });
        console.log(self.get('vars'));
      } else {
        _.each(ast, function (item) {
          if (_.isObject(item)) {
            self.extractVars(item);
          }
        })
      }
    }
  },
  // Executes visitor on the object and its children (recursively).
  traverse: function traverse(object, visitor, master) {
    var parent = master || []
      , path;

    if (visitor.call(null, object, parent) === false) {
      return;
    }

    _.each(object, function (child, key) {
      path = [ object ];
      path.push(parent);
      if (_.isObject(child)) {
        traverse(child, visitor, path);
      }
    });
  },
  clearMarkers: function () {
    _.invoke(this.markers, 'clear');
    this.markers = [];
  },
  trackCursor: function (editor) {
    var self = this
      , pos = editor.indexFromPos(editor.getCursor())
      , code = editor.getValue()
      , ast = self.get('ast')
      , node, id;

    self.clearMarkers();

    if (ast === null) {
      return;
    }

    self.traverse(ast, function (node, path) {
      if (node.type !== esprima.Syntax.Identifier) {
        return;
      }
      if (pos >= node.range[0] && pos <= node.range[1]) {
        self.markers.push(editor.markText(
          window.util.convertLoc(node.loc.start),
          window.util.convertLoc(node.loc.end),
          'identifier'
        ));
        id = node;
      }
    });

    if (!_.isUndefined(id)) {
      self.traverse(self.get('ast'), function (node, path) {
        if (node.type !== esprima.Syntax.Identifier) {
          return;
        }
        if (node !== id && node.name === id.name) {
          self.markers.push(editor.markText(
            window.util.convertLoc(node.loc.start),
            window.util.convertLoc(node.loc.end),
            'highlight'
          ));
        }
      });
    }
  },
  parse: function (text, editor) {
    var parsedResult, ast, generated, vars;
    if (inventingOnPrinciple.updating) return;
    try {
      parsedResult = window.esprima.parse(text, this.parsingOptions);
      ast = _.omit(parsedResult, 'tokens');
      this.set({
        text: text,
        tokens: parsedResult.tokens,
        ast: ast
      });

      vars = this.get('vars');
      vars.reset([], { silent: true });
      this.extractVars(ast);

      if (vars && vars.length) {
        this.trigger('change:vars');
      }

      try {
        generated = window.escodegen.generate(ast);
        this.set({
          generatedCode: generated
        });
      } catch (e) {
        console.log('gen Error', e);
      }

    } catch (e) {
      console.log('parse Error', e);
    }
  },
  tokens: function () {
    return JSON.stringify(this.get('tokens'), window.util.adjustRegexLiteral, 4);
  },
  ast: function () {
    return JSON.stringify(this.get('ast'), window.util.adjustRegexLiteral, 4);
  },
  generatedCode: function () {
    return this.get('generatedCode');
  },
  text: function () {
    return this.get('text');
  }
});
