inventingOnPrinciple.Views.ApplicationView = Backbone.View.extend({

  spacer: inventingOnPrinciple.getTemplate('spacer')(),
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

    this.model.ast
      .on('change:text', this.renderUrl, this)
      .on('change:tokens', this.renderTokens, this)
      .on('change:ast', this.renderSyntax, this)
      .on('change:decs', this.renderDeclarations, this)
      .on('change:generatedCode', this.renderGeneratedCode, this)
      .on('tracedFunctions', this.renderFunctionTraces, this)
      .on('reparse', this.parse, this)
    ;
    this.model
      .on('error', this.renderError, this)
  },
  events: {
    'change input[type=checkbox]': 'parse',
    'click .tab_link': 'switchTab',
    'click #run': 'runCode'
  },
  clearConsole: function () {
    $('#console').html('');
  },
  runCode: function() {
    this.clearConsole();
    try {
      eval(inventingOnPrinciple.model.text());
    } catch (e) {
      console.log('run time error', e);
    }
  },
  switchTab: function (e) {
    this.$('li').removeClass('active');
    $(e.currentTarget).parents('li').addClass('active');
    this.render();
  },
  trackCursor: function (editor) {
    this.model.trackCursor(editor);
  },
  parse: function (editor, changeInfo) {
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
  renderDeclarations: function () {
    var self = this;
    self.$vars.empty();

    var lines = [], linenumber;
    self.model.ast.get('vars').each(function (varDec, i) {
      linenumber = varDec.get('loc').start.line - 1;
      var view = new inventingOnPrinciple.Views.VariableView({
        model: varDec
      });

      lines[linenumber] = view;
    });

    self.model.ast.get('funs').each(function (funDec, i) {
      linenumber = funDec.get('loc').start.line - 1;
      var view = new inventingOnPrinciple.Views.FunctionView({
        model: funDec
      });
      lines[linenumber] = view;
    });

    _.each(lines, function (line) {
      if (line) {
        self.$vars.append(line.render().$el);
        if (line.initTangle) {
          line.initTangle();
        }
      } else {
        self.$vars.append(self.spacer);
      }
    })
  },
  renderFunctionTraces: function (histogram, funcs) {
    // Normalize histogram
    var max = inventingOnPrinciple.Options.max
      , normalized = {};
    _.each(histogram, function (count, funcname) {
      normalized[funcname] = count/max;
    });


    var self = this
      , $lines = this.$('#vars').children();

    _.each(funcs.reverse(), function (func) {
      var start = func.loc.start.line - 1
        , end = func.loc.end.line - 1
        , weight = normalized[func.name]
        , count = histogram[func.name]
        // , color = '#' + util.toHex(weight * 255, 2) + util.toHex(weight * 255, 2) + util.toHex(weight * 255, 2);
        , color = 'rgba(255, 0, 0, ' + util.mapValue(weight, 0.05, 0.9) + ')'
        , $lineinfo = inventingOnPrinciple.getTemplate('lineinfo')({ msg: count })
        , $linesInRange = $lines.slice(start, end);
      $linesInRange.css({
        'background-color': color
      });
      $linesInRange
        .find('.lineinfo').remove().end()
        .append($lineinfo);
    })
    return this;
  },
  clearError: function () {
    if (this.errorLineNumber >= 0) {
      inventingOnPrinciple.codeEditor.setLineClass(this.errorLineNumber, null, null);
      this.$('#codeContainer .errorContainer').html('');
    }
  },
  renderError: function (e) {
    var ln = e.lineNumber - 1;
    this.clearError();
    inventingOnPrinciple.codeEditor.setLineClass(ln, 'errorLine', 'errorLineBackground');
    this.errorLineNumber = ln;

    this.$('#codeContainer .errorContainer')
      .html(inventingOnPrinciple.getTemplate('lineinfo')({ msg: e.message }))
      .css('top', (ln + 0.5) + 'em');
    return this;
  },
  scrollVars: function (scrollInfo) {
    this.$('#decsContainer').scrollTop(scrollInfo.y);
  },
  render: function () {
    this.renderUrl();
    this.renderTokens();
    this.renderSyntax();
    this.renderGeneratedCode();
    this.renderDeclarations();
  }
});
