GLOBAL = exports ? this

tracer =
  active: false
  funcDict: {}
  varDict: {}
  statementList: []

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