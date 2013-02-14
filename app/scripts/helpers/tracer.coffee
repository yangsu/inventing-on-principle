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
      switch exp.type
        when Syntax.FunctionExpression
          params =
            name: exp.name
            range: exp.range
            loc: exp.loc
            lineNumber: if exp.loc? then exp.loc.start.line else null

          signature = window.tracer.genTraceFunc(params)

          if exp.body? and exp.body.length
            node = exp.body[0]
            node.insertBefore signature

        when Syntax.ForStatement
          signature = window.tracer.getTraceStatement
            # scope: util.scopeLookup(exp, scopes)
            data:
              init: exp.init.source()
              test: exp.test.source()
              update: exp.update.source()

          exp.body.body[0].insertBefore signature

        when Syntax.ForInStatement
          signature = window.tracer.getTraceStatement
            type: exp.type
            # scope: util.scopeLookup(exp, scopes)
            data:
              left: exp.left.source()
              right: exp.right.source()

          exp.body.body[0].insertBefore signature

        when Syntax.ExpressionStatement
          exp = exp.expression
          parent = exp.parent
          data = {}
          switch exp.type
            when Syntax.CallExpression
              data.callee = exp.callee.source()
              data.arguments = (arg.source() for arg in exp.arguments)
            when Syntax.AssignmentExpression
              data.left = exp.left.source()
              data.right = exp.right.source()

          signature = window.tracer.getTraceStatement
            type: exp.type
            data: data
            scope: util.scopeLookup(exp, scopes)

          exp.insertBefore signature

        when Syntax.ReturnStatement
          signature = window.tracer.getTraceStatement
            type: exp.type
            scope: util.scopeLookup(exp, scopes)
            data:
              argument: exp.argument.source()

          exp.insertBefore signature

  genTraceFunc: (params) ->
    paramsStr = JSON.stringify(params)
    signature = "window.tracer.traceFunc(#{paramsStr});"

  getTraceStatement: (params) ->
    scope = params.scope
    # console.log params
    paramsStr = JSON.stringify(_.omit(params, 'scope'))
    signature = "window.tracer.traceStatement(#{paramsStr});"
    if scope? and scope.vars.length
      for v in scope.vars
        signature += "window.tracer.traceVar('#{v}', #{v});"

    if params.data.argument?
      signature += "window.tracer.traceVar('returnVal', #{params.data.argument});"

    signature


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