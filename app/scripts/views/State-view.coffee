inventingOnPrinciple.Views.StateView = Backbone.View.extend
  initialize: ->
    @lines = []
    @markers = []
    $stateEditor = @$el.find('#state').get(0)
    @editor = CodeMirror.fromTextArea($stateEditor,
      mode: 'javascript'
      lineNumbers: true
      onCursorActivity: (editor) =>
        @onCursor()
      onUpdate: (editor) =>
        @onUpdate()
      onChange: (editor) =>
        @onChange()
    )


  events:
    'mousedown': 'onMouseDown'
    'mousemove': 'onMouseMove'
    'mouseup': 'onMouseUp'

    'touchstart': 'onMouseDown'
    'touchmove': 'onMouseMove'
    'touchend': 'onMouseUp'
    'touchcancel': 'onMouseUp'

    'keydown': 'onKeyDown'
    'keyup': 'onKeyUp'

  onKeyDown: (e) ->
    if e.keyCode in [Keys.Alt, Keys.LeftSuper, Keys.RightSuper]
      @controlPressed = true

  onKeyUp: (e) ->
    if e.keyCode in [Keys.Alt, Keys.LeftSuper, Keys.RightSuper]
      @controlPressed = false

  onMouseDown: (e) ->
    return unless @controlPressed
    e.stopPropagation()

    @mouseDown = true
    @prevMouse = { x: e.pageX, y: e.pageY }

  onMouseMove: (e) ->
    return unless @controlPressed
    e.stopPropagation()

    if @mouseDown
      console.log (e.pageX - @prevMouse.x), (e.pageY - @prevMouse.y)

  onMouseUp: (e) ->
    return unless @controlPressed

    e.stopPropagation()
    @mouseDown = false
    @prevMouse = null

  onCursor: ->
    cursor = @editor.getCursor()
    token = @editor.getTokenAt(cursor)

    state = @editor.getStateAfter(cursor.line)
    # console.log state

    @clearMarkers()

    marker = @editor.markText(
      util.toLoc(cursor.line, token.start),
      util.toLoc(cursor.line, token.end),
      'tangle'
    )
    @markers.push(marker)
    # console.log marker

  onUpdate: ->

  onChange: ->

  setLines: (lines) ->
    if not _.isEqual(@lines, lines)
      @lines = lines
      @render()

  clearMarkers: ->
    _.invoke(@markers, 'clear')
    @markers = []

  scrollTo: (scrollInfo) ->
    @editor.scrollTo(scrollInfo.x, scrollInfo.y)

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


