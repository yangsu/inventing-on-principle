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

    func =
      node: node
      range: node.range
      loc: node.loc
      body: if node.body? then node.body.body

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
      functionList.push _.extend(func, name: name)

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
    functionList = []
    forList = []
    statementMap = {}

    @pretraverse (node) =>
      @extractFunction(node, functionList)
      # @extractFor(node, forList)
      type = node.type.slice(0, -9)
      if node.type.slice(-9) is 'Statement' and type isnt 'Block'
        if statementMap[type]
          statementMap[type].push node
        else
          statementMap[type] = [node]

    chunks = @get('chunks')
    chunksCopy = _.clone(chunks)

    # Functions ----------------------------------------------------------------
    @set 'functionList', functionList

    for func in functionList
      params =
        name: func.name
        range: func.range
        loc: func.loc
        lineNumber: if func.loc? then func.loc.start.line else null

      signature = window.tracer.genTraceFunc(params)

      if func.body? and func.body.length
        node = func.body[0]
        node.updateSource(signature + '\n' + node.source());

    # For Statment -------------------------------------------------------------
    @set 'forList', forList

    for own type, statements of statementMap
      for statement in statements
        signature = window.tracer.getTraceStatement
          type: statement.type
        statement.updateSource(signature + '\n' + statement.source());

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
    @trigger 'tracedFunctions', hist, functionList

    list = window.tracer.getStatementList()
    @trigger 'tracedStatements', list, statementMap


    window.tracer.active = false

    this

  extractDeclarations: ->
    declarationMap = {}

    @pretraverse (node) ->
      if node.type.slice(-11) is 'Declaration'
        type = node.type.slice(0, -11)
        model = new inventingOnPrinciple.Models[type + 'Model'](node)
        if declarationMap[type]
          declarationMap[type].push model
        else
          declarationMap[type] = [model]

    vars = declarationMap['Variable']
    @get('vars').reset vars
    funs = declarationMap['Function']
    @get('funs').reset funs
    @trigger 'change:decs', vars, funs

    this

  onASTChange: ->
    try
      generated = window.escodegen.generate(@get('ast'))
      @set generatedCode: generated
    catch e
      console.log 'gen Error', e
