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
    lists =
      function: []
      for: []
      forIn: []
      expression: []

    @pretraverse (node) =>
      @extractFunction(node, lists.function)
      if node.type is Syntax.ForStatement
        lists.for.push(node)
      else if node.type is Syntax.ForInStatement
        lists.forIn.push(node)
      else if node.type is Syntax.ExpressionStatement
        lists.expression.push(node)

    console.log _.invoke(lists.expression, 'source');

    chunks = @get('chunks')
    chunksCopy = _.clone(chunks)

    # Functions ----------------------------------------------------------------
    for func in lists.function
      params =
        name: func.name
        range: func.range
        loc: func.loc
        lineNumber: if func.loc? then func.loc.start.line else null

      signature = window.tracer.genTraceFunc(params)

      if func.body? and func.body.length
        node = func.body[0]
        node.insertBefore(signature);

    # For Statment -------------------------------------------------------------
    for forStatement in lists.for
      signature = window.tracer.getTraceStatement
        type: forStatement.type
        # scope: util.scopeLookup(forStatement, @scopes)
        data:
          init: forStatement.init.source()
          test: forStatement.test.source()
          update: forStatement.update.source()

      forStatement.body.body[0].insertBefore(signature);

    # ForIn Statment -------------------------------------------------------------
    for forInStatement in lists.forIn
      signature = window.tracer.getTraceStatement
        type: forInStatement.type
        # scope: util.scopeLookup(forInStatement, @scopes)
        data:
          left: forInStatement.left.source()
          right: forInStatement.right.source()

      forInStatement.body.body[0].insertBefore(signature);

    # Expression Statment -------------------------------------------------------------
    for expStatement in lists.expression
      exp = expStatement.expression
      parent = expStatement.parent
      data = {}
      switch exp.type
        when Syntax.CallExpression
          data.callee = exp.callee.source()
          data.arguments = (arg.source() for arg in exp.arguments)

      signature = window.tracer.getTraceStatement
        type: expStatement.type
        data: data
        scope: util.scopeLookup(expStatement, @scopes)

      expStatement.insertBefore(signature);

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
    @trigger 'tracedFunctions', hist, lists.function

    list = window.tracer.getStatementList()
    @trigger 'tracedStatements', list, lists

    vars = window.tracer.getVars()
    @trigger 'tracedVars', vars, lists

    window.tracer.active = false

    this

  buildScope: ->
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

  buildScope2: ->
    ast = @get 'ast'
    @scopes =
      global:
        node: ast
        vars: []
        funcs: []

    @posttraverse (node) ->
      scope = util.scopeLookup(node, @scopes)

      switch (node.type)
        when Syntax.VariableDeclarator
          scope.vars.push node.id.name
        when Syntax.FunctionDeclaration
          scope.funcs.push node.id.name
          @scopes[node.id.name] =
            node: node
            parent: scope
            vars: []
            funcs: []
        else

    console.log @scopes

    this

  onASTChange: ->
    try
      generated = window.escodegen.generate(@get('ast'))
      @set generatedCode: generated
    catch e
      console.log 'gen Error', e
