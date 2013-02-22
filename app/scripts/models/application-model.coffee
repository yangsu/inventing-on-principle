inventingOnPrinciple.Models.ApplicationModel = Backbone.Model.extend

  initialize: ->
    @ast = new inventingOnPrinciple.Models.ASTModel()

  trackCursor: (cursorLoc, cursorIndex) ->
    return if @ast is null

    markers =
      indentifier: []
      highlight: []

    id = null

    @ast.pretraverse (node) =>
      if node? and node.type is Syntax.Identifier and util.withinRange(cursorIndex, node.range)
        markers.indentifier.push node.loc
        id = node

    if id?
      @ast.pretraverse (node) =>
        if node? and node.type is Syntax.Identifier and node isnt id and node.name is id.name
          markers.highlight.push node.loc

    markers

  updateHints: (editor) ->
    editor.operation =>
      JSHINT editor.getValue()

      for err in JSHINT.errors
        continue unless err?
        @trigger 'error', err

    info = editor.getScrollInfo()
    after = editor.charCoords(
      line: editor.getCursor().line + 1
      ch: 0
    , 'local').top

    if info.top + info.clientHeight < after
      editor.scrollTo null, after - info.clientHeight + 3

  parse: (text, editor) ->
    # if (text == this.ast.toSource()) return

    return if inventingOnPrinciple.updating

    @updateHints(editor)

    try
      @ast.setSource(text);
      @ast
        .extractDeclarations?()
        .buildScope?()
        .instrumentFunctions?()
    catch e
      # console.log(e.name + ': ' + e.message)
      # console.log(@ast.get('ast').source())
      # console.trace(e)
      @trigger('error', e)

  tokens: ->
    JSON.stringify(@ast.get('tokens'), util.adjustRegexLiteral, 4)

  generatedCode: ->
    @ast.get('generatedCode')

  text: ->
    @ast.toSource()
