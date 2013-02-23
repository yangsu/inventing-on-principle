var editor;
var p = null;
var throttle = 100;

var canvas = document.getElementById('canvas');

var widgets = [];

var clearWidgets = function() {
  for (var i = 0; i < widgets.length; ++i)
    editor.removeLineWidget(widgets[i]);
  widgets = [];
};

var updateHints = function(e) {
  e && editor && editor.operation(function() {
    clearWidgets();
    var msg = document.createElement('div');
    var icon = msg.appendChild(document.createElement('span'));
    icon.innerHTML = '!';
    icon.className = 'lint-error-icon';
    msg.appendChild(document.createTextNode(e.message));
    msg.className = 'lint-error';

    widgets.push(editor.addLineWidget(editor.getCursor().line, msg, {coverGutter: false, noHScroll: true}));
  });
};

var runProcessing = function() {
  if (p) {
    p.exit();
    delete p;
  }
  var setup = 'void setup(){ size(500, 500); }\n';
  try {
    p = new Processing(canvas, setup + window.editor.getValue());
  } catch (e) {
    console.log(e);
    updateHints(e);
  }
};

window.onload = function() {
  var sc = document.getElementById('script');
  var content = sc.textContent || sc.innerText || sc.innerHTML;
  content = content.replace(/^\s+|\s+$/g, '');

  var waiting;

  try {
    CodeMirror.commands.autocomplete = function(cm) {
      CodeMirror.showHint(cm, CodeMirror.processingHint);
    };

    editor = CodeMirror(document.getElementById('code'), {
      lineNumbers: true,
      mode: 'javascript',
      value: content,
      extraKeys: {'Ctrl-Space': 'autocomplete'}
    });

    editor.on('change', function(editor, changeInfo) {
      clearTimeout(waiting);
      waiting = setTimeout(runProcessing, throttle);
      clearWidgets();
    });
  } catch (e) {
    console.log('CodeMirror failed to initialize');
  }

  setTimeout(runProcessing, throttle);
};
