GLOBAL = exports ? this

GLOBAL.inventingOnPrinciple =

  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Templates: {}
  Options:
    max: 200

  init: ->
    @model = new inventingOnPrinciple.Models.ApplicationModel()
    @view = new inventingOnPrinciple.Views.ApplicationView
      el: '#main'
      model: @model

  getTemplate: (templateName) ->
    path = 'scripts/templates/' + templateName + '.ejs'
    (context) ->
      unless inventingOnPrinciple.Templates[path]
        $.ajax(
          url: path
          async: false
        ).then (contents) ->
          inventingOnPrinciple.Templates[path] = _.template(contents)

      inventingOnPrinciple.Templates[path] context

$ ->
  inventingOnPrinciple.init()
  try
    window.checkEnv()
    inventingOnPrinciple.codeEditor = CodeMirror.fromTextArea(document.getElementById('code'),
      lineNumbers: true
      matchBrackets: true
      onScroll: (editor) ->
        inventingOnPrinciple.view.scrollVars editor.getScrollInfo()

      onCursorActivity: (editor) ->
        inventingOnPrinciple.view.trackCursor editor

      onChange: (editor, changeInfo) ->
        inventingOnPrinciple.view.clearError()
        inventingOnPrinciple.view.parse editor, changeInfo
    )
    $.get '/scripts/source.js', (source) ->
      inventingOnPrinciple.codeEditor.setValue source

    inventingOnPrinciple.outputcode = CodeMirror.fromTextArea(document.getElementById('outputcode'),
      mode: 'javascript'
      lineNumbers: true
      readOnly: true
    )

    inventingOnPrinciple.state = CodeMirror.fromTextArea(document.getElementById('state'),
      mode: 'javascript'
      lineNumbers: true
    )
  catch e
    console.log 'CodeMirror failed to initialize'

  inventingOnPrinciple.view.parse()

  $console = $('#console')
  window.log = (message) ->

    # DO MESSAGE HERE.
    text = $console.html()
    text += (message + ' ')
    $console.html text
    $console.scrollTop ($console[0].scrollHeight - $console.height())

  window.genTangle 'span[data-container=max]', inventingOnPrinciple.Options, ->
    inventingOnPrinciple.Options.max = @max
    inventingOnPrinciple.view.parse()


