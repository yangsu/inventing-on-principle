GLOBAL = exports ? this

tracer =
  active: false
  funcDict: {}
  varDict: {}
  varLocDict: {}
  statementList: []

  reset: ->
    @funcDict = {}
    @statementList = []
    @varDict = {}
    @varLocDict = {}

  # ############################################################################
  # Trace Generators
  # ############################################################################

  genTraces: (trackList, scopes) ->
    @reset()

    for exp in trackList
      scope = util.scopeLookup exp, scopes
      loc = exp.loc
      signature = ''
      insertLocation = 'Before'

      switch exp.type
        when Syntax.FunctionExpression, Syntax.FunctionDeclaration
          params =
            name: exp.name
            range: exp.range
            loc: loc

          # signature += window.tracer.genTraceStatement params
          signature += window.tracer.genTraceFunc params
          # signature += window.tracer.genTraceVar loc, 'arguments', scope

          # FunctionExpression
          if exp.body? and exp.body.length
            exp = exp.body[0]
          # FunctionDeclaration
          else if exp.body.body? and exp.body.body.length
            exp = exp.body.body[0]


        when Syntax.ForStatement
          signature += window.tracer.genTraceStatement
            loc: loc
            data:
              init: exp.init and exp.init.source()
              test: exp.test.source()
              update: exp.update.source()

          exp = exp.body.body[0]

        when Syntax.VariableDeclaration
          signature += window.tracer.genTraceStatement
            loc: loc

          for vardec in exp.declarations
            signature += window.tracer.genTraceVar loc, vardec.id.name, scope
            insertLocation = 'After'

          # Trace variables declared in ForExp.init at the beginning of the ForExp body
          if exp.parent? and exp.parent.type in [Syntax.ForStatement, Syntax.ForInStatement]
            exp = exp.parent.body.body[0]
            insertLocation = 'Before'

        when Syntax.ForInStatement
          left = exp.left
          right = exp.right
          signature += window.tracer.genTraceStatement
            loc: loc
            data:
              left: left.source()
              right: right.source()

          if left.type is Syntax.Identifier
            signature += window.tracer.genTraceVar loc, left.name, scope

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
              insertLocation = 'After'

              switch expression.left.type
                when Syntax.Identifier
                  signature += window.tracer.genTraceVar loc, expression.left.name, scope
                when Syntax.MemberExpression
                  signature += window.tracer.genTraceVar loc, expression.left.object.name, scope

          signature += window.tracer.genTraceStatement
            loc: loc
            data: data
            scope: scope

        when Syntax.ReturnStatement
          signature += window.tracer.genTraceStatement
            loc: loc
            scope: scope
          returnVal = if exp.argument? then exp.argument.source() else 'null'
          signature += window.tracer.genTraceVar loc, 'return', scope, returnVal

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
    ln = loc.start.line - 1

    # nameWithLoc = "#{name}.#{ln}"
    # unless util.objGet(tracer.varDict, nameWithLoc)?
    #   util.objSet(tracer.varDict, nameWithLoc, [])
    # util.objGet(tracer.varDict, nameWithLoc).push _.clone value
    # tracer.varLocDict[nameWithLoc] = name;

    nameAllTraces = "#{name}.all"
    unless util.objGet(tracer.varDict, nameAllTraces)?
      util.objSet(tracer.varDict, nameAllTraces, [])
    util.objGet(tracer.varDict, nameAllTraces).push _.clone value
    tracer.varLocDict[nameAllTraces] = name;

  toIndexMap: (obj) ->
    _.reduce obj, (memo, value, k) =>
      memo[k] = if _.isArray value then value.length - 1 else @toIndexMap value
      memo
    , {}

  traceStatement: (params) ->
    tracer.statementList.push _.extend params,
      vars : @toIndexMap @varDict
      varLocs : _.cloneDeep @varLocDict

  indexMapToVarDict: (map, prefix = '') ->
    _.reduce map, (memo, value, key) =>
      k = "#{prefix}#{key}"

      if _.isObject value
        memo[key] = @indexMapToVarDict value, "#{k}."
      else
        memo[key] = util.objGet @varDict, "#{k}.#{value}"

      memo
    , {}

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