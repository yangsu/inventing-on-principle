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

  instrumentFunctions: ->
    functionList = []

    @pretraverse (node) =>
      @extractFunction(node, functionList)

    chunks = @get('chunks')
    chunksCopy = _.clone(chunks)

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
    window.tracer.active = false

    this

  extractDeclarations: ->
    declarationMap = {}
    statementMap = {}
    expressionMap = {}

    @pretraverse (node) ->
      if node.type.slice(-11) is 'Declaration'
        type = node.type.slice(0, -11)
        model = new inventingOnPrinciple.Models[type + 'Model'](node)
        if declarationMap[type]
          declarationMap[type].push model
        else
          declarationMap[type] = [model]
      else if node.type.slice(-9) is 'Statement'
        type = node.type.slice(0, -9)
        if statementMap[type]
          statementMap[type].push node
        else
          statementMap[type] = [node]
      else if node.type.slice(-10) is 'Expression'
        type = node.type.slice(0, -10)
        if expressionMap[type]
          expressionMap[type].push node
        else
          expressionMap[type] = [node]

    vars = declarationMap['Variable']
    @get('vars').reset vars
    funs = declarationMap['Function']
    @get('funs').reset funs
    @trigger 'change:decs', vars, funs


    console.log statementMap
    console.log expressionMap

    this

  onASTChange: ->
    try
      generated = window.escodegen.generate(@get('ast'))
      @set generatedCode: generated
    catch e
      console.log 'gen Error', e
