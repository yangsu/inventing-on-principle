
window.inventingOnPrinciple = {
  Models: {},
  Collections: {},
  Views: {},
  Routers: {},
  init: function() {
    this.model = new inventingOnPrinciple.Models.ApplicationModel();
    this.view = new inventingOnPrinciple.Views.ApplicationView({
      el: '#main',
      model: this.model
    });
  }
};

$(document).ready(function(){
  inventingOnPrinciple.init();

  try {
    window.checkEnv();

    inventingOnPrinciple.codeEditor = CodeMirror.fromTextArea(document.getElementById("code"), {
      lineNumbers: true,
      matchBrackets: true,
      onChange: function () {
        inventingOnPrinciple.view.parse();
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
});
