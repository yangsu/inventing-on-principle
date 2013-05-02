inventingOnPrinciple.Views.ApplicationView = Backbone.View.extend
  spacer: inventingOnPrinciple.getTemplate('spacer')()

  initialize: ->

    # Input
    @$code = $('#code')

    # Options
    @$comment = $('#comment')
    @$loc = $('#loc')
    @$range = $('#range')
    @$raw = $('#raw')

    # Output
    @$tokens = $('#tokens')
    @$syntax = $('#syntax')
    @$url = $('#url')
    @$vars = $('#vars')

    # Tabs
    @$syntaxTab = $('#tab_syntax')
    @$tokensTab = $('#tab_tokens')
    @$urlTab = $('#tab_url')
    @$codeTab = $('#tab_code')
    @$stateTab = $('#tab_state')

    # Slider
    @$slider = $ '#slider'
    @$step = $ '#step'
    @$total = $ '#total'

    @highlightedLines = []

    @showHints = false

    @model
      .on('change:text', @renderUrl, this)
      .on('change:tokens', @renderTokens, this)
      .on('change:ast', @renderSyntax, this)
      .on('change:decs', @renderDeclarations, this)
      .on('change:generatedCode', @renderGeneratedCode, this)
      .on('tracedFunctions', @renderFunctionTraces, this)
      .on('tracedStatements', @renderStatementTraces, this)
      .on('tracedVars', @renderVarsTraces, this)
      .on('reparse', @parse, this)

    @model.on('error', @renderError, this)

  events:
    'change #showvars': 'toggleVars'

  toggleVars: (e) ->
    checked = $(e.target).prop('checked')

    $varhint = @$('.var-hint')
    if checked
      $varhint.removeClass('hidden').slideDown('fast')
    else
      $varhint.slideUp('fast', ->
        $(this).addClass('hidden')
      )

    @showHints = checked

  clearConsole: ->
    $('#console').html ''

  markers: []
  clearMarkers: ->
    _.invoke(@markers, 'clear')
    @markers = []

  widgets: [],
  clearWidgets: ->
    for widget in @widgets
      inventingOnPrinciple.codeEditor.removeLineWidget widget
    @widgets = []

  addWidget: (line, msg) ->
    @widgets.push inventingOnPrinciple.codeEditor.addLineWidget(line, msg,
      coverGutter: false
      noHScroll: true
    )

  trackCursor: (editor) ->

    cursor = editor.getCursor()
    cursorIndex = editor.indexFromPos(cursor)

    @clearMarkers()

    markerMap = @model.trackCursor cursor, cursorIndex

    for own markerClass, markerArray of markerMap
      for loc in markerArray
        marker = editor.markText(
          util.convertLoc(loc.start),
          util.convertLoc(loc.end),
          markerClass
        )
        @markers.push(marker)

  parse: (editor, changeInfo) ->
    editor ?= inventingOnPrinciple.codeEditor
    text = if editor? then editor.getValue() else @$code.val()
    @clearWidgets()
    @model.parse text, editor

  renderUrl: ->
    @$url.val "#{location.protocol}//#{location.host}#{location.pathname}?code=#{encodeURIComponent(@model.text())}"

  renderTokens: ->
    tokens = _.map @model.tokens(), (token) -> type: token.type, value: token.value

    @$tokens.html inventingOnPrinciple.getTemplate('tokens')(tokens: tokens)

  renderSyntax: ->
    @$syntax.html @model.astString()

  renderGeneratedCode: ->
    inventingOnPrinciple.outputcode.setValue @model.generatedCode()

  renderDeclarations: ->
    @$vars.empty()
    lines = []
    linenumber = undefined
    @model.get('vars').each (varDec, i) ->
      linenumber = varDec.get('loc').start.line - 1
      view = new inventingOnPrinciple.Views.VariableView(model: varDec)
      if lines[linenumber]?
        lines[linenumber].push view
      else
        lines[linenumber] = [view]

    @model.get('funs').each (funDec, i) ->
      linenumber = funDec.get('loc').start.line - 1
      view = new inventingOnPrinciple.Views.FunctionView(model: funDec)
      if lines[linenumber]?
        lines[linenumber].push view
      else
        lines[linenumber] = [view]

    _.each lines, (line) =>
      if line
        $line = $('<div class="varDecs"></div>')
        for i in line
          $line.append i.render().$el
        @$vars.append $line
        for i in line
          i.initTangle() if i.initTangle

      else
        @$vars.append @spacer

    inventingOnPrinciple.stateView.setLines(lines)

  renderFunctionTraces: (histogram, funcs) ->

    max = inventingOnPrinciple.Options.max
    normalized = {}
    _.each histogram, (count, funcname) ->
      normalized[funcname] = count / max

    $lines = @$('#vars').children()

    # Clear previous function traces
    $lines.css('background-color', 'transparent')

    _.each funcs.reverse(), (func) ->
      start = func.loc.start.line - 1
      end = func.loc.end.line - 1
      weight = normalized[func.name]
      count = histogram[func.name]

      color = 'rgba(255, 0, 0, ' + util.mapValue(weight, 0.05, 0.9) + ')'
      $lineinfo = inventingOnPrinciple.getTemplate('lineinfo')(msg: count)
      $linesInRange = $lines.slice(start, end)
      $linesInRange.css 'background-color': color
      $linesInRange.find('.lineinfo').remove().end().append $lineinfo

    this

  highlightLines: (begin, end) ->
    where = 'background'
    cssClass = 'highlight-line'
    range = _.range(begin, end + 1)

    for ln in @highlightedLines
      inventingOnPrinciple.codeEditor.removeLineClass ln, where, cssClass

    for ln in range
      inventingOnPrinciple.codeEditor.addLineClass ln, where, cssClass

    @highlightedLines = range

  renderStatementTraces: (list) ->
    locs = _.pluck(list, 'loc')

    start = 0
    end = locs.length - 1

    @$slider.slider
      range: 'min',
      min: start,
      max: end,
      value: start,
      slide: (event, ui) =>
        @$step.html ui.value
        trace = list[ui.value - start]
        loc = trace.loc
        # if not loc?
        #   debugger
        @highlightLines loc.start.line - 1, loc.end.line - 1

        @clearWidgets()
        @renderVarsTraces trace

    @$step.html start
    @$total.html end

    # for i in list
    #   console.log i.type, i.data

  renderVarsTraces: (list) ->
    vars = list.vars
    varLocs = list.varLocs

    for own k, name of varLocs
      values = util.objGet(vars, k)
      vals = util.formatVal(values, util.unscopeName name)
      ln = +(util.unscopeName k)

      varTraceElement = $(inventingOnPrinciple.getTemplate('varHint')(
        vals: vals
        show: @showHints
      )).get(0)

      allArrays = _.all(values, (val) -> _.isArray val)
      if allArrays
        el = $(inventingOnPrinciple.getTemplate('arrayVis')(
          values: values
          show: @showHints
        )).get(0)

        plot = _.map values[values.length-1], (v, i) -> [i, v]
        if k is 'insertionSort.list.all'
          console.log (_.map plot, (p) -> "(#{p[0]},#{p[1]})").join(' ')
          window.updateD3(plot)

        # @addWidget ln, el if not _.isNaN ln
      else
        # @addWidget ln, varTraceElement if not _.isNaN ln

      # CodeMirror.runMode(
      #   vals,
      #     name: "javascript"
      #     # json: true
      #   , varTraceElement
      # );

    # CodeMirror.runMode(
    #   util.formatVarJSON(vars),
    #     name: "javascript",
    #     json: true,
    #     lineNumbers: true
    #   , document.getElementById('varsPre')
    # );

    info = inventingOnPrinciple.codeEditor.getScrollInfo()
    after = inventingOnPrinciple.codeEditor.charCoords(
      line: inventingOnPrinciple.codeEditor.getCursor().line + 1
      ch: 0
    , 'local').top

    if info.top + info.clientHeight < after
      inventingOnPrinciple.codeEditor.scrollTo null, after - info.clientHeight + 3

  renderError: (e) ->

    # Either the lineNumber is contained in the error object
    # Or guess that the error was due to the last change and use cursor's position
    ln = if e.lineNumber then e.lineNumber - 1 else inventingOnPrinciple.codeEditor.getCursor().line

    e.reason ?= e.message
    msg = $(inventingOnPrinciple.getTemplate('hint')(e)).get(0)

    @addWidget(ln, msg)

  scrollVars: (scrollInfo) ->
    @$('#decsContainer').scrollTop scrollInfo.y

    inventingOnPrinciple.stateView.scrollTo(scrollInfo)

  render: ->
    @renderUrl()
    @renderTokens()
    @renderSyntax()
    @renderGeneratedCode()
    @renderDeclarations()
