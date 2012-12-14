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
