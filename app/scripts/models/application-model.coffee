inventingOnPrinciple.Models.ApplicationModel = Backbone.Model.extend

  markers: []

  initialize: ->
    @ast = new inventingOnPrinciple.Models.ASTModel()

  clearMarkers: ->
    _.invoke(@markers, 'clear')
    @markers = []

  trackCursor: (editor) ->
    pos = editor.indexFromPos(editor.getCursor())
    @clearMarkers()

    return if @ast is null

    id = null

    @ast.pretraverse (node) =>
      if node? and node.type is Syntax.Identifier and util.withinRange(pos, node.range)
        marker = editor.markText(util.convertLoc(node.loc.start), util.convertLoc(node.loc.end), 'identifier')
        @markers.push(marker)
        id = node

    if id?
      @ast.pretraverse (node) =>
        if node? and node.type is Syntax.Identifier and node isnt id and node.name is id.name
          marker = editor.markText(util.convertLoc(node.loc.start), util.convertLoc(node.loc.end), 'highlight')
          @markers.push(marker)

  parse: (text, editor) ->
    # if (text == this.ast.toSource()) return;

    return if inventingOnPrinciple.updating

    try
      @ast.setSource(text)
        .buildScope?()
        .instrumentFunctions?()

    catch e
      console.log(e.name + ': ' + e.message);
      # console.log(e);
      console.trace(e);
      @trigger('error', e)

  tokens: ->
    JSON.stringify(@ast.get('tokens'), util.adjustRegexLiteral, 4)

  generatedCode: ->
    @ast.get('generatedCode')

  text: ->
    @ast.toSource()
