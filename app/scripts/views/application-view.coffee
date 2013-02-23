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

    @model.ast
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
    # 'change input[type=checkbox]': 'parse'
    'click .tab_link': 'switchTab'

  toggleVars: (e) ->
    checked = !!$(e.target).attr('checked')
    op = if checked then 'slideDown' else 'slideUp'

    @$('.var-hint')[op]('fast')

  clearConsole: ->
    $('#console').html ''

  switchTab: (e) ->
    @$('li').removeClass 'active'
    $(e.currentTarget).parents('li').addClass 'active'
    @render()

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
    @$url.val location.protocol + '//' + location.host + location.pathname + '?code=' + encodeURIComponent(@model.text())  if @$urlTab.hasClass('active')

  renderTokens: ->
    @$tokens.html @model.tokens()  if @$tokensTab.hasClass('active')

  renderSyntax: ->
    @$syntax.html @model.ast()  if @$syntaxTab.hasClass('active')

  renderGeneratedCode: ->
    inventingOnPrinciple.outputcode.setValue @model.generatedCode()  if @$codeTab.hasClass('active')

  renderDeclarations: ->
    @$vars.empty()
    lines = []
    linenumber = undefined
    @model.ast.get('vars').each (varDec, i) ->
      linenumber = varDec.get('loc').start.line - 1
      view = new inventingOnPrinciple.Views.VariableView(model: varDec)
      if lines[linenumber]?
        lines[linenumber].push view
      else
        lines[linenumber] = [view]

    @model.ast.get('funs').each (funDec, i) ->
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

  renderStatementTraces: (list) ->
    # console.log(map)
    # for i in list
    #   console.log i.type, i.data

  renderVarsTraces: (list) ->
    vars = list.vars
    varLocs = list.varLocs

    for own k, v of varLocs
      vals = util.formatVal util.objGet(vars, k), util.unscopeName k
      ln = v.end.line - 1

      varTraceElement = $(inventingOnPrinciple.getTemplate('varHint')(vals: vals)).get(0)

      @addWidget(ln, varTraceElement)

      CodeMirror.runMode(
        vals,
          name: "javascript"
          # json: true
        , varTraceElement
      );

    CodeMirror.runMode(
      util.formatVarJSON(vars),
        name: "javascript",
        json: true
      , document.getElementById('varsPre')
    );

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
