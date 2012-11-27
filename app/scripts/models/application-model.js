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
    this.on('change:ast', this.onASTChange, this)
  },
  onASTChange: function () {
    try {
      var generated = window.escodegen.generate(this.get('ast'));
      this.set({
        generatedCode: generated
      });
    } catch (e) {
      // console.log('gen Error', e);
    }
  },
  processUpdate: function () {
    debugger;
  },
  extractVars: function (ast, text) {
    var self = this;
    // if (_.isArray(ast)) {
    //   _.each(ast, function (item) {
    //     self.extractVars(item);
    //   })
    // } else if (_.isObject(ast)) {
    //   if (ast.type == 'VariableDeclaration') {
    //   } else {
    //     _.each(ast, function (item) {
    //       if (_.isObject(item)) {
    //         self.extractVars(item);
    //       }
    //     })
    //   }
    // }
    window.falafel(text, function (node) {
      if (node.type === 'VariableDeclaration') {
      // node.update('fn(' + node.source() + ')');
        var varModel = new inventingOnPrinciple.Models.VariableModel(node);
        self.get('vars').add(varModel, { silent: true });
      }
    });
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
  setVar: function (key, value) {
    var self = this
      , changed = false;
    var updated = window.falafel(this.get('text'), function (node) {
      if (node.type === 'VariableDeclaration') {
        _.each(node.declarations, function (dec) {
          if (dec.id.name == key && dec.init.value != value) {

            dec.init.value = value;
            dec.init.update(value);

            changed = true;
          }
        });
      }
    });

    if (changed) {
      inventingOnPrinciple.updating = true;
      this.set('text', updated.toString());
      inventingOnPrinciple.codeEditor.setValue(updated.toString());
      inventingOnPrinciple.view.runCode();
      inventingOnPrinciple.updating = false;
    }
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
    if (text == this.get('text')) return;

    if (inventingOnPrinciple.updating) {
      return;
    }

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
      this.extractVars(ast, text);

      if (vars && vars.length) {
        this.trigger('change:vars');
      }

      inventingOnPrinciple.view.runCode();
    } catch (e) {
      // console.log('parse Error', e);
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
