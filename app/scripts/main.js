
window.inventingOnPrinciple = {
  Models: {},
  Collections: {},
  Views: {},
  Routers: {},
  init: function() {
    console.log('Hello from Backbone!');
  }
};

$(document).ready(function(){
  inventingOnPrinciple.init();

  function updateTree(syntax) {

    if (window.tree) {
      window.tree.destroy();
      window.tree = null;
    }

    if (typeof syntax === 'undefined') {
      return;
    }

    if (!$('#tab_tree').hasClass('active')) {
      return;
    }

    window.tree = new YAHOO.widget.TreeView("treeview");
    $('#collapse').click(function () {
      window.tree.collapseAll();
    });

    $('#expand').click(function () {
      window.tree.expandAll();
    });

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

    window.tree.subscribe('focusChanged', function (args) {
      var from, to;

      function convert(loc) {
        return {
          line: loc.line - 1,
          ch: loc.column
        };
      }

      if (window.editorMark) {
        window.editorMark.clear();
        delete window.editorMark;
      }
      if (args.newNode && args.newNode.data && args.newNode.data.loc) {
        from = convert(args.newNode.data.loc.start);
        to = convert(args.newNode.data.loc.end);
        window.editorMark = window.editor.markText(from, to, 'highlight');
      }
    });

    window.tree.buildTreeFromObject(convert('Program body', syntax.body));
    window.tree.render();
  }

  var parse = _.throttle(function () {
    var code, options, result, el, str;

    // Special handling for regular expression literal since we need to
    // convert it to a string literal, otherwise it will be decoded
    // as object "{}" and the regular expression would be lost.

    function adjustRegexLiteral(key, value) {
      if (key === 'value' && value instanceof RegExp) {
        value = value.toString();
      }
      return value;
    }

    if (typeof window.editor === 'undefined') {
      code = document.getElementById('code').value;
    } else {
      code = window.editor.getValue();
    }
    options = {
      comment: document.getElementById('comment').checked,
      raw: document.getElementById('raw').checked,
      range: document.getElementById('range').checked,
      loc: document.getElementById('loc').checked
    };

    document.getElementById('tokens').value = '';

    try {

      result = esprima.parse(code, options);

      var generated = escodegen.generate(result);
      outputcode.setValue(generated);

      str = JSON.stringify(result, adjustRegexLiteral, 4);

      options.tokens = true;

      var tokens = esprima.parse(code, options).tokens;
      $('#tokens').val(JSON.stringify(tokens, adjustRegexLiteral, 4));

      updateTree(result);
    } catch (e) {
      updateTree();

      str = e.name + ': ' + e.message;

      // Code gen
      outputcode.setValue(str);
    }

    $('#syntax').val(str);
    $('#url').val(location.protocol + "//" + location.host + location.pathname + '?code=' + encodeURIComponent(code));
  }, 10);

  $('#show_tree, #show_syntax, #show_tokens, #show_url, #show_code').click(function (e) {
    $('#tab_tree, #tab_syntax, #tab_tokens, #tab_url, #tab_code').removeClass('active');
    $(e.target).parents('li').addClass('active');
    parse();
  });

  try {
    $('#comment, #raw, #range, #loc, #tokens').bind('change', parse);

    window.checkEnv();

    window.editor = CodeMirror.fromTextArea(document.getElementById("code"), {
      lineNumbers: true,
      matchBrackets: true,
      onChange: parse
    });

    window.outputcode = CodeMirror.fromTextArea(document.getElementById('outputcode'), {
      mode: 'javascript',
      lineNumbers: true,
      readOnly: true
    });

  } catch (e) {
    console.log('CodeMirror failed to initialize');
  }
  parse();

});
