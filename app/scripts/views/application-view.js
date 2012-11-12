inventingOnPrinciple.Views.ApplicationView = Backbone.View.extend({
  initialize: function () {
    // Input
    this.$code = $('#code');

    // Options
    this.$comment = $('#comment');
    this.$loc = $('#loc');
    this.$range = $('#range');
    this.$raw = $('#raw');

    // Output
    this.$tokens = $('#tokens');
    this.$syntax = $('#syntax');
    this.$url = $('#url');

    this.$syntaxTab = $('#tab_syntax');
    this.$tokensTab = $('#tab_tokens');
    this.$urlTab = $('#tab_url');
    this.$codeTab = $('#tab_code');

    this.model
      .on('change:text', this.renderUrl, this)
      .on('change:tokens', this.renderTokens, this)
      .on('change:ast', this.renderSyntax, this)
      .on('change:generatedCode', this.renderGeneratedCode, this);
  },
  events: {
    'change input[type=checkbox]': 'parse',
    'click .tab_link': 'switchTab'
  },
  switchTab: function (e) {
    this.$('li').removeClass('active');
    $(e.currentTarget).parents('li').addClass('active');
    this.render();
  },
  parse: function () {
    var text, options;

    if (_.isUndefined(inventingOnPrinciple.codeEditor)) {
      text = this.$code.val();
    } else {
      text = inventingOnPrinciple.codeEditor.getValue();
    }
    options = {
      comment: this.$comment.attr('checked'),
      raw: this.$raw.attr('checked'),
      range: this.$range.attr('checked'),
      loc: this.$loc.attr('checked')
    };
    this.model.parse(text, options);
  },
  renderUrl: function () {
    if (this.$urlTab.hasClass('active')) {
      this.$url.val(location.protocol + "//" + location.host + location.pathname + '?code=' + encodeURIComponent(this.model.text()));
    }
  },
  renderTokens: function () {
    if (this.$tokensTab.hasClass('active')) {
      this.$tokens.val(this.model.tokens());
    }
  },
  renderSyntax: function () {
    if (this.$syntaxTab.hasClass('active')) {
      this.$syntax.val(this.model.ast());
    }
  },
  renderGeneratedCode: function () {
    if (this.$codeTab.hasClass('active')) {
      inventingOnPrinciple.outputcode.setValue(this.model.generatedCode());
    }
  },
  render: function () {
    this.renderUrl();
    this.renderTokens();
    this.renderSyntax();
    this.renderGeneratedCode();
  }
});
