inventingOnPrinciple.Models.ApplicationModel = Backbone.Model.extend({
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
  parse: function (text, options) {
    var parsedResult, ast, generated, vars;
    if (inventingOnPrinciple.updating) return;
    try {
      options.tokens = true;
      parsedResult = window.esprima.parse(text, options);
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
        generated = window.escodegen.generate(ast.body);
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
