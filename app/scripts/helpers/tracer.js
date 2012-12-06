(function (global, _) {
  var tracer = {};

  tracer.active = false;

  tracer.funcDict = {};

  tracer.traceFunc = function (params) {
    if (!tracer.active) return;
    var name = params.name;
    if (tracer.funcDict[name]) {
      tracer.funcDict[name] += 1;
    } else {
      tracer.funcDict[name] = 1;
    }
  };

  tracer.funcHistogram = function () {
    var histogram = _.clone(tracer.funcDict);
    tracer.funcDict = {};
    return histogram;
  };

  global.tracer = tracer;
}(window, _));