GLOBAL = exports ? this

tracer =
  active: false
  funcDict: {}
  varDict: {}
  varLocDict: {}
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

          if exp.body? and exp.body.length
            exp = exp.body[0]
          # FunctionDeclaration
          else if exp.body.body? and exp.body.body.length
            exp = exp.body.body[0]

          signature += window.tracer.genTraceVar exp.loc, 'arguments', scope

        when Syntax.ForStatement
          signature += window.tracer.genTraceStatement
            data:
              init: exp.init.source()
              test: exp.test.source()
              update: exp.update.source()

          exp = exp.body.body[0]

        when Syntax.VariableDeclaration
          for vardec in exp.declarations
            signature += window.tracer.genTraceVar exp.loc, vardec.id.name, scope
            insertLocation = 'After'

          # Trace variables declared in ForExp.init at the beginning of the ForExp body
          if exp.parent? and exp.parent.type in [Syntax.ForStatement, Syntax.ForInStatement]
            exp = exp.parent.body.body[0]
            insertLocation = 'Before'


        when Syntax.ForInStatement
          left = exp.left
          right = exp.right
          signature += window.tracer.genTraceStatement
            data:
              left: left.source()
              right: right.source()

          exp = exp.body.body[0]

          if left.type is Syntax.Identifier
            signature += window.tracer.genTraceVar exp.loc, left.name, scope

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
              insertLocation = 'After'

              switch expression.left.type
                when Syntax.Identifier
                  signature += window.tracer.genTraceVar exp.loc, expression.left.name, scope
                when Syntax.MemberExpression
                  signature += window.tracer.genTraceVar exp.loc, expression.left.object.name, scope

          signature += window.tracer.genTraceStatement
            data: data
            scope: scope

        when Syntax.ReturnStatement
          signature += window.tracer.genTraceStatement
            scope: scope
          signature += window.tracer.genTraceVar exp.loc, 'return', scope, exp.argument.source()

      exp['insert' + insertLocation] signature

  genTraceFunc: (params) ->
    paramsStr = JSON.stringify(params)
    "window.tracer.traceFunc(#{paramsStr});"

  genTraceVar: (loc, varname, scope, value = varname) ->
    scopedVarname = util.scopeName varname, scope
    "window.tracer.traceVar(#{JSON.stringify(loc)}, '#{scopedVarname}', #{value});"

  genTraceStatement: (params) ->
    scope = params.scope
    paramsStr = JSON.stringify(_.omit(params, 'scope'))
    "window.tracer.traceStatement(#{paramsStr});"

  # ############################################################################
  # Tracers
  # ############################################################################

  traceVar: (loc, name, value) ->

    unless util.objGet(tracer.varDict, name)?
      util.objSet(tracer.varDict, name, [])

    util.objGet(tracer.varDict, name).push _.clone value

    tracer.varLocDict[name] = loc

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
    vars = _.clone(@varDict)
    @varDict = {}
    varLocs = _.clone(@varLocDict)
    @varLocDict = {}

    vars: vars,
    varLocs: varLocs

GLOBAL.tracer = tracer;