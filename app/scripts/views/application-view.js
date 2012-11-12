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
    'change #comment,#raw,#range,#loc,#tokens': 'parse',
    'click .tab_link': 'switchTab',
    'click #expand': 'expandTree',
    'click #collapse': 'collapseTree'
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

      this.updateTree(result);
    } catch (e) {
      this.updateTree();

      str = e.name + ': ' + e.message;

      window.outputcode.setValue(str);
    }

    this.$syntax.val(str);
    this.$url.val(location.protocol + "//" + location.host + location.pathname + '?code=' + encodeURIComponent(code));
  },

  collapseTree: function () {
    this.tree && this.tree.collapseAll();
  },
  expandTree: function () {
    this.tree && this.tree.expandAll();
  },

  updateTree: function (syntax) {

    if (this.tree) {
      this.tree.destroy();
      this.tree = null;
    }

    if (_.isUndefined(syntax) || !$('#tab_tree').hasClass('active')) {
      return;
    }

    this.tree = new YAHOO.widget.TreeView("treeview");

    function convert(name, node) {
      var result, i, key, value, child;

      switch (typeof node) {
      case 'string':
        return {
          type: 'Text',
          label: name + ': ' + node
        };
      case 'number':
      case 'boolean':
        return {
          type: 'Text',
          label: name + ': ' + String(node)
        };
      case 'object':
        if (!node) {
          return {
            type: 'Text',
            label: name + ': null'
          };
        }
        if (node instanceof RegExp) {
          return {
            type: 'Text',
            label: name + ': ' + node.toString()
          };
        }
        result = {
          type: 'Text',
          label: name,
          expanded: true,
          children: []
        };
        if (_.isArray(node)) {
          if (node.length === 2 && name === 'range') {
            result.label = name + ': [' + node[0] + ', ' + node[1] + ']';
          } else {
            result.label = result.label + ' [' + node.length + ']';
            for (i = 0; i < node.length; i += 1) {
              key = String(i);
              value = node[i];
              child = convert(key, value);
              if (_.isArray(child.children) && child.children.length === 1) {
                result.children.push(child.children[0]);
              } else {
                result.children.push(convert(key, value));
              }
            }
          }
        } else {
          if (typeof node.type !== 'undefined') {
            result.children.push({
              type: 'Text',
              label: node.type,
              expanded: true,
              children: [],
              data: node
            });
            _.each(node, function(value, key) {
              result.children[0].children.push(convert(key, value));
            });
          } else {
            _.each(node, function(value, key) {
              result.children.push(convert(key, value));
            });
          }
        }
        return result;

      default:
        break;
      }

      return {
        type: 'Text',
        label: '?'
      };
    }

    this.tree.subscribe('focusChanged', function (args) {
      var from, to;

      function convert(loc) {
        return {
          line: loc.line - 1,
          ch: loc.column
        };
      }

      if (this.editorMark) {
        this.editorMark.clear();
        delete this.editorMark;
      }
      if (args.newNode && args.newNode.data && args.newNode.data.loc) {
        from = convert(args.newNode.data.loc.start);
        to = convert(args.newNode.data.loc.end);
        this.editorMark = inventingOnPrinciple.codeEditor.markText(from, to, 'highlight');
      }
    });

    this.tree.buildTreeFromObject(convert('Program body', syntax.body));
    this.tree.render();
  }
});
