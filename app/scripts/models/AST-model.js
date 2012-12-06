(function (jQuery, _, Backbone, inventingOnPrinciple, esprima) {
  var insertHelpers = function (node, parent, chunks, depth) {
    if (!node.range) return;

    node.depth = depth;
    node.parent = parent;

    node.source = function () {
      return chunks.slice(node.range[0], node.range[1]).join('');
    };

    node.update = function (s) {
      chunks[node.range[0]] = s;
      for (var i = node.range[0] + 1; i < node.range[1]; i++) {
        chunks[i] = '';
      }
    };
  };

  var traverse = function (ast, chunks, prefunc, postfunc) {
    var ctx = this;
    (function walk (node, parent, depth) {
      postfunc && postfunc.call(ctx, node, parent, chunks, depth);

      _.each(node, function (child, key) {
        if (key === 'parent' || key === 'range' || key === 'loc') return;

        if (_.isArray(child)) {
          _.each(child, function (grandchild) {
            if (grandchild && typeof grandchild.type === 'string') {
              walk(grandchild, node, depth + 1);
            }
          })
        } else if (child && typeof child.type === 'string') {
          postfunc && postfunc.call(ctx, child, node, chunks, depth);
          walk(child, node, depth);
        }
      });

      prefunc && prefunc.call(ctx, node, parent, chunks);
    })(ast, undefined, 0);
  };

  inventingOnPrinciple.Models.ASTModel = Backbone.Model.extend({
    defaults: {
      parsingOptions: {
        // Range is required
        range: true,
        // comment: true,
        loc: true,
        raw: true,
        tokens: true
      },
    },
    initialize: function (attributes, options) {
      if (attributes && attributes.text) {
        this.setSource(attributes.text, options);
      }

      var vars = new inventingOnPrinciple.Collections.VariableCollection;
      var funs = new inventingOnPrinciple.Collections.FunctionCollection;

      this.set({
        vars: vars,
        funs: funs
      }, { silent: true });

      var self = this;
      vars.on('change', function () {
        inventingOnPrinciple.updating = true;
        inventingOnPrinciple.codeEditor.setValue(self.toSource());
        inventingOnPrinciple.view.runCode();
        inventingOnPrinciple.updating = false;

        // Instrument Function
        self.extractFunctions();
      }).on('endChange', function () {
        self.trigger('reparse');
        self.extractFunctions();
      })
    },
    setSource: function (text, options) {
      if (typeof text !== 'string') {
        text = String(text);
      }

      var parsedResult = window.esprima.parse(text, this.get('parsingOptions'))
        , tokens= parsedResult.tokens
        , ast = _.omit(parsedResult, 'tokens')
        , chunks = text.split('');

      this.set({
        ast: ast,
        chunks: chunks,
        tokens: tokens
      }, options);

      this.posttraverse(insertHelpers);

      return this;
    },
    toSource: function () {
      return (this.get('ast') && this.get('ast').source()) || '';
    },
    traverse: function (prefunc, postfunc) {
      var ast = this.get('ast')
        , chunks = this.get('chunks');

      if (ast && chunks) {
        traverse.call(this, ast, chunks, prefunc, postfunc);
      }
    },
    pretraverse: function (f) {
      this.traverse(f);
    },
    posttraverse: function (f) {
      this.traverse(null, f);
    },
    extractFunction: function (node, functionList) {
      var parent = node.parent
        , func = {
          node: node
        };
      if (node.type === Syntax.FunctionDeclaration) {
        _.extend(func, {
          name: node.id.name,
          range: node.range,
          loc: node.loc,
          blockStart: node.body.range[0]
        });
      } else if (node.type === Syntax.FunctionExpression) {
        if (parent.type === Syntax.AssignmentExpression) {
          if (typeof parent.left.range !== 'undefined') {
            _.extend(func, {
              name: code.slice(parent.left.range[0],
                  parent.left.range[1] + 1),
              range: node.range,
              loc: node.loc,
              blockStart: node.body.range[0]
            });
          }
        } else if (parent.type === Syntax.VariableDeclarator) {
          _.extend(func, {
            name: parent.id.name,
            range: node.range,
            loc: node.loc,
            blockStart: node.body.range[0]
          });
        } else if (parent.type === Syntax.CallExpression) {
          _.extend(func, {
            name: parent.id ? parent.id.name : '[Anonymous]',
            range: node.range,
            loc: node.loc,
            blockStart: node.body.range[0]
          });
        } else if (typeof parent.length === 'number') {
          _.extend(func, {
            name: parent.id ? parent.id.name : '[Anonymous]',
            range: node.range,
            loc: node.loc,
            blockStart: node.body.range[0]
          });
        } else if (typeof parent.key !== 'undefined') {
          if (parent.key.type === 'Identifier') {
            if (parent.value === node && parent.key.name) {
              _.extend(func, {
                name: parent.key.name,
                range: node.range,
                loc: node.loc,
                blockStart: node.body.range[0]
              });
            }
          }
        }
      }
      if (func.name) {
        functionList.push(func);
      }
    },
    instrumentFunctions: function () {
      // Insert the instrumentation code from the last entry.
      // This is to ensure that the range for each entry remains valid)
      // (it won't shift due to some new inserting string before the range).
      var functionList = this.get('functionList')
        , source = this.get('ast').source()
        , traceFunc = 'window.tracer.traceFunc'
        , signature, pos;

      for (var i = 0, l = functionList.length; i < l; i += 1) {
        var func = functionList[i]
          , param = {
            name: func.name,
            range: func.range,
            loc: func.loc
          }
          , signature = '';
        if (typeof traceFunc === 'function') {
          signature = traceFunc.call(null, param);
        } else {
          signature = traceFunc + '({ ';
          signature += 'name: \'' + func.name + '\', ';
          if (typeof func.loc !== 'undefined') {
            signature += 'lineNumber: ' + func.loc.start.line + ', ';
          }
          signature += 'range: [' + func.range[0] + ', ' +
            func.range[1] + '] ';
          signature += '});';
        }
        pos = func.blockStart + 1;
        source = source.slice(0, pos) + '\n' + signature + source.slice(pos);
      }

      window.tracer.active = true;

      try {
        eval(source);
        var hist = window.tracer.funcHistogram();
        console.log(JSON.stringify(hist));
        this.trigger('tracedFunctions', hist, functionList);
      } catch (e) {
        console.log(e);
        console.trace(e);
        console.log(source);
      }

      window.tracer.active = false;
      return this;
    },
    extractFunctions: function () {
      var functionList = []
        , self = this;

      this.pretraverse(function (node) {
        self.extractFunction(node, functionList);
      });

      this
        .set('functionList', functionList)
        .instrumentFunctions();
    },
    extractDeclarations: function () {
      var map = {}
        , self = this;

      this.pretraverse(function (node) {
        var type = node.type.slice(0, -11);
        if (node.type.slice(-11) === 'Declaration') {
          var model = new inventingOnPrinciple.Models[type + 'Model'](node);
          if (map[type]) {
            map[type].push(model);
          } else {
            map[type] = [model];
          }
        }
      });

      var vars = map['Variable'];
      this.get('vars').reset(vars);
      var funs = map['Function'];
      this.get('funs').reset(funs);

      this.trigger('change:decs', vars, funs);

      this.extractFunctions();
    },
    onASTChange: function () {
      try {
        var generated = window.escodegen.generate(this.get('ast'));
        this.set({
          generatedCode: generated
        });
      } catch (e) {
        console.log('gen Error', e);
      }
    }

  });

})(jQuery, _, Backbone, inventingOnPrinciple, esprima)
