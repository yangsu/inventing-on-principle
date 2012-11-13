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
    this.$vars = $('#vars');

    // Tabs
    this.$syntaxTab = $('#tab_syntax');
    this.$tokensTab = $('#tab_tokens');
    this.$urlTab = $('#tab_url');
    this.$codeTab = $('#tab_code');
    this.$stateTab = $('#tab_state');

    this.model
      .on('change:text', this.renderUrl, this)
      .on('change:tokens', this.renderTokens, this)
      .on('change:ast', this.renderSyntax, this)
      .on('change:vars', this.renderVars, this)
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
  parse: function (editor) {
    var text;
    if (_.isUndefined(inventingOnPrinciple.codeEditor)) {
      text = this.$code.val();
    } else {
      text = inventingOnPrinciple.codeEditor.getValue();
    }
    this.model.parse(text, editor);
  },
  renderUrl: function () {
    if (this.$urlTab.hasClass('active')) {
      this.$url.val(location.protocol + "//" + location.host + location.pathname + '?code=' + encodeURIComponent(this.model.text()));
    }
  },
  renderTokens: function () {
    if (this.$tokensTab.hasClass('active')) {
      this.$tokens.html(this.model.tokens());
    }
  },
  renderSyntax: function () {
    if (this.$syntaxTab.hasClass('active')) {
      this.$syntax.html(this.model.ast());
    }
  },
  renderGeneratedCode: function () {
    if (this.$codeTab.hasClass('active')) {
      inventingOnPrinciple.outputcode.setValue(this.model.generatedCode());
    }
  },
  renderVars: function () {
    var self = this;
    self.$vars.empty();
    self.model.get('vars').each(function (varDec) {
      var view = new inventingOnPrinciple.Views.VariableView({
        model: varDec
      });
      self.$vars.append(view.render().$el);
      view.initTangle();
    });
  },
  render: function () {
    this.renderUrl();
    this.renderTokens();
    this.renderSyntax();
    this.renderGeneratedCode();
    this.renderVars();
  }
});
