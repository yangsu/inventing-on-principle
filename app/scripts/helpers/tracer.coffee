GLOBAL = exports ? this

tracer =
  active: false
  funcDict: {}
  traceFunc: (params) ->
    return  unless tracer.active
    name = params.name
    if tracer.funcDict[name]
      tracer.funcDict[name] += 1
    else
      tracer.funcDict[name] = 1

  funcHistogram : ->
    histogram = _.clone(tracer.funcDict)
    tracer.funcDict = {}
    histogram

GLOBAL.tracer = tracer;