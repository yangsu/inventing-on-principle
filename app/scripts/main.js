
window.inventingOnPrinciple = {
  Models: {},
  Collections: {},
  Views: {},
  Routers: {},
  Templates: {},
  init: function() {
    this.model = new inventingOnPrinciple.Models.ApplicationModel();
    this.view = new inventingOnPrinciple.Views.ApplicationView({
      el: '#main',
      model: this.model
    });
  },
  getTemplate: function (templateName) {
    var path = 'scripts/templates/' + templateName + ".ejs";

    return function (context) {
      if (!inventingOnPrinciple.Templates[path]) {
        $.ajax({ url: path, async: false }).then(function(contents) {
          inventingOnPrinciple.Templates[path] = _.template(contents);
        });
      }
      return inventingOnPrinciple.Templates[path](context);
    };
  }
};

$(document).ready(function(){
  inventingOnPrinciple.init();

  try {
    window.checkEnv();

    inventingOnPrinciple.codeEditor = CodeMirror.fromTextArea(document.getElementById("code"), {
      lineNumbers: true,
      matchBrackets: true,
      onCursorActivity: function (editor) {
        inventingOnPrinciple.view.trackCursor(editor);
      },
      onChange: function (editor, changeInfo) {
        inventingOnPrinciple.view.parse(editor, changeInfo);
      }
    });

    inventingOnPrinciple.outputcode = CodeMirror.fromTextArea(document.getElementById('outputcode'), {
      mode: 'javascript',
      lineNumbers: true,
      readOnly: true
    });

  } catch (e) {
    console.log('CodeMirror failed to initialize');
  }

  inventingOnPrinciple.view.parse();

  var oldLog = console.log;
  var $console = $('#console');
  console.log = function (message) {
    // DO MESSAGE HERE.
    var text = $console.html();
    text += (message + ' ');
    $console.html(text);

    $console.scrollTop(
      $console[0].scrollHeight - $console.height()
    );

    oldLog.apply(console, arguments);
  };
});
