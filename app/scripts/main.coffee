GLOBAL = exports ? this

GLOBAL.inventingOnPrinciple =

  Models: {}
  Collections: {}
  Views: {}
  Routers: {}
  Templates: {}
  Options:
    max: 200

  init: ->
    @model = new inventingOnPrinciple.Models.ApplicationModel()
    @view = new inventingOnPrinciple.Views.ApplicationView
      el: '#main'
      model: @model

  getTemplate: (templateName) ->
    inventingOnPrinciple.Templates[templateName]

$ ->
  inventingOnPrinciple.init()
  try
    inventingOnPrinciple.codeEditor = CodeMirror.fromTextArea(document.getElementById('code'),
      lineNumbers: true
      matchBrackets: true
    )
    inventingOnPrinciple.codeEditor.on('scroll', (editor) ->
      inventingOnPrinciple.view.scrollVars editor.getScrollInfo()
    )
    inventingOnPrinciple.codeEditor.on('cursorActivity', (editor) ->
      inventingOnPrinciple.view.trackCursor editor
    )
    inventingOnPrinciple.codeEditor.on('change', (editor, changeInfo) ->
      inventingOnPrinciple.view.parse editor, changeInfo
    )

    $.get '/scripts/source2.js', (source) ->
      inventingOnPrinciple.codeEditor.setValue source
    , 'text'

    # inventingOnPrinciple.outputcode = CodeMirror.fromTextArea(document.getElementById('outputcode'),
    #   mode: 'javascript'
    #   lineNumbers: true
    #   readOnly: true
    # )

    # inventingOnPrinciple.stateView = new inventingOnPrinciple.Views.StateView
    #   el: '#stateContainer'


  catch e
    console.log e
    console.log 'CodeMirror failed to initialize'

  inventingOnPrinciple.view.parse()


  $console = $('#console')
  window.log = (message) ->

    # DO MESSAGE HERE.
    text = $console.html()
    text += (message + ' ')
    $console.html text
    $console.scrollTop ($console[0].scrollHeight - $console.height())

  window.genTangle 'span[data-container=max]', inventingOnPrinciple.Options, ->
    inventingOnPrinciple.Options.max = @max
    inventingOnPrinciple.view.parse()

  #Width and height
  w = 500
  h = 200

  svg = d3.select('#tab_d3')
    .append('svg')
    .attr('width', w)
    .attr('height', h)

  window.initD3 = _.once((data) ->
    xs = _.pluck(data, '0');
    ys = _.pluck(data, '1');

    radius = w / data.length / 5

    xscale = d3.scale.linear().domain([_.min(xs), _.max(xs)]).range([radius, w - radius])
    yscale = d3.scale.linear().domain([_.min(ys), _.max(ys)]).range([radius, h - radius])

    window.xf = (d) -> xscale(d[0])
    window.yf = (d) -> yscale(d[1])

    svg.selectAll('circle')
      .data(data)
      .enter()
      .append('circle')
      .attr('cx', xf)
      .attr('cy', yf)
      .attr 'r', radius

    svg.selectAll('text')
      .data(data)
      .text((d) -> "(#{d[0]},#{d[1]})")
      .attr('x', xf)
      .attr('y', yf)
  )

  window.updateD3 = (data) ->
    window.initD3(data);

    svg.selectAll('circle')
      .data(data)
      # .transition().duration(50)
      .attr('cx', xf)
      .attr('cy', yf)
    svg.selectAll('text')
      .data(data)
      # .transition().duration(50)
      .text((d) -> "(#{d[0]},#{d[1]})")
      .attr('x', xf)
      .attr('y', yf)




