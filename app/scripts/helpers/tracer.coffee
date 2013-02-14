GLOBAL = exports ? this

tracer =
  active: false
  funcDict: {}
  varDict: {}
  statementList: []

  # ############################################################################
  # Trace Generators
  # ############################################################################

  genTraces: (trackList, scopes) ->
    for exp in trackList
      scope = util.scopeLookup exp, scopes
      signature = ''
      insertLocation = 'Before'

      switch exp.type
        when Syntax.FunctionExpression, Syntax.FunctionDeclaration
          params =
            name: exp.name
            range: exp.range
            loc: exp.loc
            lineNumber: if exp.loc? then exp.loc.start.line else null

          signature += window.tracer.genTraceFunc params
          signature += window.tracer.genTraceVar 'arguments', scope

          if exp.body? and exp.body.length
            exp = exp.body[0]

        when Syntax.ForStatement
          signature += window.tracer.genTraceStatement
            data:
              init: exp.init.source()
              test: exp.test.source()
              update: exp.update.source()

          exp = exp.body.body[0]

        when Syntax.VariableDeclaration
          for vardec in exp.declarations
            signature += window.tracer.genTraceVar vardec.id.name, scope
            insertLocation = 'After'

        when Syntax.ForInStatement
          signature += window.tracer.genTraceStatement
            data:
              left: exp.left.source()
              right: exp.right.source()

          exp = exp.body.body[0]

        when Syntax.ExpressionStatement
          expression = exp.expression
          parent = expression.parent
          data = {}
          switch expression.type
            when Syntax.CallExpression
              data.callee = expression.callee.source()
              data.arguments = (arg.source() for arg in expression.arguments)
            when Syntax.AssignmentExpression
              data.left = expression.left.source()
              data.right = expression.right.source()
              signature += window.tracer.genTraceVar data.left, scope
              insertLocation = 'After'

          signature += window.tracer.genTraceStatement
            data: data
            scope: scope

        when Syntax.ReturnStatement
          signature += window.tracer.genTraceStatement
            scope: scope
          signature += window.tracer.genTraceVar 'returnVal', scope, exp.argument.source()

      exp['insert' + insertLocation] signature

  genTraceFunc: (params) ->
    paramsStr = JSON.stringify(params)
    "window.tracer.traceFunc(#{paramsStr});"

  genTraceVar: (varname, scope, value = varname) ->
    scopedVarname = util.scopeName varname, scope
    "window.tracer.traceVar('#{scopedVarname}', #{value});"

  genTraceStatement: (params) ->
    scope = params.scope
    paramsStr = JSON.stringify(_.omit(params, 'scope'))
    "window.tracer.traceStatement(#{paramsStr});"

  # ############################################################################
  # Tracers
  # ############################################################################

  traceVar: (name, value) ->
    tracer.varDict[name] = [] unless tracer.varDict[name]?
    tracer.varDict[name].push value

  traceStatement: (params) ->
    tracer.statementList.push params

  traceFunc: (params) ->
    return unless tracer.active
    name = params.name
    if tracer.funcDict[name]
      tracer.funcDict[name] += 1
    else
      tracer.funcDict[name] = 1


  # ############################################################################
  # Getters
  # ############################################################################

  funcHistogram : ->
    histogram = _.clone(tracer.funcDict)
    tracer.funcDict = {}
    histogram

  getStatementList : ->
    list = _.clone(tracer.statementList)
    tracer.statementList = []
    list

  getVars : ->
    vars = _.clone(tracer.varDict)
    tracer.varDict = {}
    vars

GLOBAL.tracer = tracer;