inventingOnPrinciple.Views.ApplicationView = Backbone.View.extend({
  initialize: function () {
    this.$code = $('#code');
    this.$comment = $('#comment');
    this.$loc = $('#loc');
    this.$range = $('#range');
    this.$raw = $('#raw');
    this.$tokens = $('#tokens');
    this.$tab_link = $('.tab_link');
    this.$syntax = $('#syntax');
    this.$url = $('#url');
  },
  events: {
    'change input[type=checkbox]': 'parse',
    'click .tab_link': 'switchTab'
  },
  switchTab: function (e) {
    this.$tab_link.parents('li').removeClass('active');
    $(e.currentTarget).parents('li').addClass('active');
    this.parse();
  },
  parse: function () {
    var code, options, result, el, str;

    if (typeof inventingOnPrinciple.codeEditor === 'undefined') {
      code = this.$code.val();
    } else {
      code = inventingOnPrinciple.codeEditor.getValue();
    }
    options = {
      comment: this.$comment.attr('checked'),
      raw: this.$raw.attr('checked'),
      range: this.$range.attr('checked'),
      loc: this.$loc.attr('checked')
    };

    this.$tokens.val('');

    try {

      result = window.esprima.parse(code, options);

      var generated = window.escodegen.generate(result);
      window.outputcode.setValue(generated);

      str = JSON.stringify(result, window.util.adjustRegexLiteral, 4);

      options.tokens = true;

      var tokens = window.esprima.parse(code, options).tokens;
      this.$tokens.val(JSON.stringify(tokens, window.util.adjustRegexLiteral, 4));

    } catch (e) {

      str = e.name + ': ' + e.message;

      window.outputcode.setValue(str);
    }

    this.$syntax.val(str);
    this.$url.val(location.protocol + "//" + location.host + location.pathname + '?code=' + encodeURIComponent(code));
  }
});
