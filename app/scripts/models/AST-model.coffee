inventingOnPrinciple.Models.ASTModel = Backbone.Model.extend
  defaults:
    parsingOptions:
      # Range is required
      range: true
      # comment: true,
      loc: true
      raw: true
      tokens: true

  initialize: (attributes, options) ->
    if attributes? and attributes.text?
      @setSource(attributes.text, options)

    vars = new inventingOnPrinciple.Collections.VariableCollection()
    funs = new inventingOnPrinciple.Collections.FunctionCollection()

    @set({
      vars: vars
      funs: funs
    }, {
      silent: true
    })

    vars
    .on 'change:var', =>
      inventingOnPrinciple.updating = true
      inventingOnPrinciple.codeEditor.setValue(@toSource())
      inventingOnPrinciple.updating = false
      @instrumentFunctions()
    .on 'endChange', =>
      @trigger 'reparse'


  setSource: (text, options) ->
    return unless typeof text is 'string'

    parsedResult = esprima.parse(text, @get('parsingOptions'))

    tokens = parsedResult.tokens
    ast = _.omit(parsedResult, 'tokens')
    chunks = text.split ''

    @set({
      ast: ast
      chunks: chunks
      tokens: tokens
    }, options)

    @posttraverse util.insertHelpers
    this

  toSource: ->
    @get('ast').source?()

  traverse: (prefunc, postfunc, ast) ->
    ast ?= @get('ast')
    chunks = @get('chunks')
    if ast? and chunks?
      util.traverse.call(this, ast, chunks, prefunc, postfunc)

  pretraverse: (f, ast) ->
    @traverse(f, null, ast)

  posttraverse: (f, ast) ->
    @traverse(null, f, ast)

  extractFunction: (node, functionList) ->
    parent = node.parent

    name = ''

    if node.type is Syntax.FunctionDeclaration
      name = node.id.name

    else if node.type is Syntax.FunctionExpression
      if parent.type is Syntax.AssignmentExpression and parent.left.range?
        name = code.slice(parent.left.range[0], parent.left.range[1] + 1)

      else if parent.type is Syntax.VariableDeclarator
        name = parent.id.name

      else if parent.type is Syntax.CallExpression
        name = if parent.id then parent.id.name else '[Anonymous]'

      else if typeof parent.length is 'number'
        name = if parent.id then parent.id.name else '[Anonymous]'

      else if parent.key?
        if parent.key.type is Syntax.Identifier and parent.value is node and parent.key.name
          name = parent.key.name

    if name? and name.length
      functionList.push _.extend(node, name: name)

  extractFor: (node, forList) ->
    parent = node.parent

    forStmt =
      node: node
      loc: node.loc
      body: if node.body? then node.body.body


    if node.type is Syntax.ForStatement
      forStmt.init = node.init
      forStmt.test = node.test
      forStmt.update = node.update

      forList.push forStmt

  instrumentFunctions: ->
    trackList = []

    @pretraverse (node) =>
      @extractFunction(node, trackList)
      if node.type in [
        Syntax.ForStatement,
        Syntax.ForInStatement,
        Syntax.ExpressionStatement,
        Syntax.VariableDeclaration,
        Syntax.ReturnStatement
      ]
        trackList.push(node)

    chunks = @get('chunks')
    chunksCopy = _.clone(chunks)

    window.tracer.genTraces(trackList, @scopes)

    # Store updated source with function traces
    source = @get('ast').source()

    # Reset chunks
    for chunk, i in chunksCopy
      chunks[i] = chunksCopy[i]

    window.tracer.active = true
    inventingOnPrinciple.view.clearConsole()

    try
      eval(source)
    catch e
      console.log(e.toString())
      console.log(e)
      console.log(source)

    hist = window.tracer.funcHistogram()
    funs = _.filter trackList, (exp) -> exp.type is Syntax.FunctionExpression
    @trigger 'tracedFunctions', hist, funs

    list = window.tracer.getStatementList()
    @trigger 'tracedStatements', list

    vars = window.tracer.getVars()
    @trigger 'tracedVars', vars

    window.tracer.active = false

    this

  extractDeclarations: ->
    ast = @get 'ast'
    scope = {}
    vars = []
    funs = []

    @pretraverse (node) ->
      if node.type is Syntax.VariableDeclarator
        model = new inventingOnPrinciple.Models.VariableModel(node)
        vars.push model
      else if node.type is Syntax.FunctionDeclaration
        model = new inventingOnPrinciple.Models.FunctionModel(node)
        funs.push(node)

    @get('vars').reset vars
    @get('funs').reset funs
    @trigger 'change:decs', vars, funs

    this

  buildScope: ->
    ast = @get 'ast'
    @scopes =
      global:
        name: 'global'
        node: ast
        vars: []
        funcs: []

    @posttraverse (node) ->
      scope = util.scopeLookup(node, @scopes)

      switch (node.type)
        when Syntax.VariableDeclarator
          scope.vars.push node.id.name
        when Syntax.FunctionDeclaration
          scopedName = util.scopeName node.id.name, scope
          scope.funcs.push scopedName
          @scopes[scopedName] =
            name: scopedName
            node: node
            parent: scope
            vars: ['arguments']
            funcs: []
        else

    this

  onASTChange: ->
    try
      generated = window.escodegen.generate(@get('ast'))
      @set generatedCode: generated
    catch e
      console.log 'gen Error', e
