inventingOnPrinciple.Models.ApplicationModel = Backbone.Model.extend({
  initialize: function () {
  },
  parse: function (text, options) {
    var ast, generated;
    try {
      options.tokens = true;
      ast = window.esprima.parse(text, options);

      this.set({
        text: text,
        tokens: ast.tokens,
        ast: _.omit(ast, 'tokens')
      });

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
