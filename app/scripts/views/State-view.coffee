inventingOnPrinciple.Views.StateView = Backbone.View.extend
  initialize: ->
    @lines = []
    $stateEditor = @$el.find('#state').get(0)
    @editor = CodeMirror.fromTextArea($stateEditor,
      mode: 'javascript'
      lineNumbers: true
      onCursorActivity: (editor) =>
        @onCursor
      onUpdate: (editor) =>
        @onUpdate
      onChange: (editor) =>
        @onChange
    )
  events:
    'mouseMove': 'onMouseMove'

  onMouseMove: ->

  onCursor: ->

  onUpdate: ->

  onChange: ->

  setLines: (lines) ->
    if not _.isEqual(@lines, lines)
      @lines = lines
      @render()

  render: ->
    markers = []
    code =
      for line, i in @lines
        if line?
          list = []

          for view in line
            list.push view.renderText().replace(/[\s\n\r\t]+/g, ' ')
            end =
              line: i
              ch: list.join(', ').length

            if view.model.get('type') is Syntax.VariableDeclarator
              ctx = view.model.toTemplateContext()
              if ctx.type is Syntax.Literal and not isNaN(+ctx.value)
                value = String(ctx.value)
                markers.push
                  #@TODO take into account multiple lines and obj literals
                  start:
                    line: i
                    ch: end.ch - value.length
                  end: end
                  model: view.model

          list.join(', ')
        else
          ''

    @editor.setValue code.join('\n')


