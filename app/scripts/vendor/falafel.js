(function (esprima) {
  var parse = esprima.parse;

  window.falafel = function (src, opts, fn) {
    if (typeof opts === 'function') {
      fn = opts;
      opts = {};
    }
    if (typeof src === 'object') {
      opts = src;
      src = opts.source;
      delete opts.source;
    }
    src = src || opts.source;
    opts.range = true;
    if (typeof src !== 'string') src = String(src);

    var ast = parse(src, opts);

    var result = {
      chunks: src.split(''),
      toString: function () {
        return result.chunks.join('')
      },
      inspect: function () {
        return result.toString()
      }
    };
    var index = 0;

    (function walk(node, parent) {
      insertHelpers(node, parent, result.chunks);

      _.each(node, function (child, key) {
        if (key === 'parent') return;

        if (_.isArray(child)) {
          _.each(child, function (grandchild) {
            if (grandchild && typeof grandchild.type === 'string') {
              walk(grandchild, node);
            }
          })
        } else if (child && typeof child.type === 'string') {
          insertHelpers(child, node, result.chunks);
          walk(child, node);
        }
      });

      fn(node);
    })(ast, undefined);

    return result;
  };

  function insertHelpers(node, parent, chunks) {
    if (!node.range) return;

    node.parent = parent;

    node.source = function () {
      return chunks.slice(node.range[0], node.range[1]).join('');
    };

    // if (_.isObject(node.update)) {
    //   console.log(node);
    //   var prev = node.update;
    //   _.each(prev, function (value, key) {
    //     update[key] = value;
    //   })
    // }

    node.update = update;

    function update(s) {
      chunks[node.range[0]] = s;
      for (var i = node.range[0] + 1; i < node.range[1]; i++) {
        chunks[i] = '';
      }
    };
  };
})(window.esprima);