var p = null;
var throttle = 100;

var canvas = document.getElementById('canvas');

var runProcessing = function() {
  if (p) {
    p.exit();
    delete p;
  }
  var setup = 'void setup(){ size(500, 500); }\n';
  p = new Processing(canvas, setup + window.editor.getValue());

};

window.onload = function() {
  var sc = document.getElementById('script');
  var content = sc.textContent || sc.innerText || sc.innerHTML;

  var waiting;

  try {
    window.editor = CodeMirror(document.getElementById('code'), {
      lineNumbers: true,
      mode: 'javascript',
      value: content
    });
    window.editor.on('change', function(editor, changeInfo) {
      clearTimeout(waiting);
      waiting = setTimeout(runProcessing, throttle);
    });
  } catch (e) {
    console.log(e);
    console.log('CodeMirror failed to initialize');
  }

  setTimeout(runProcessing, throttle);
};
