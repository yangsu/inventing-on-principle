GLOBAL = exports ? this

tracer =
  active: false
  funcDict: {}
  statementList: []

  genTraceFunc: (params) ->
    paramsStr = JSON.stringify(params)
    signature = "window.tracer.traceFunc(#{paramsStr});"

  getTraceStatement: (params) ->
    paramsStr = JSON.stringify(params)
    signature = "window.tracer.traceStatement(#{paramsStr});"

  traceStatement: (params) ->
    tracer.statementList.push(params);

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

GLOBAL.tracer = tracer;