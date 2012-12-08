GLOBAL = exports ? this

util = {}

###*
 * Special handling for regular expression literal since we need to
 * convert it to a string literal, otherwise it will be decoded
 * as object "{}" and the regular expression would be lost.
 * @param  {[type]} key   [description]
 * @param  {[type]} value [description]
 * @return {[type]}       [description]
###
util.adjustRegexLiteral = (key, value) ->
  value.toString() if key is 'value' and value instanceof RegExp


###*
 * Convert codeMirror location object to 0 based index for lines
 * @param  {Location Object} loc has both 'line' and 'ch' positions.
 * @return {Location Object}     normalized location.
###
util.convertLoc = (loc) ->
  line: loc.line - 1
  ch: loc.column


###*
 * Test to see if a position is within a codeMirror Range array
 * @param  {int} pos   position.
 * @param  {array} range (range[0], range[1]).
 * @return {boolean}       true if pos is within range, false otherwise.
###
util.withinRange = (pos, range) ->
  range? and range.length is 2 and range[0] <= pos <= range[1]


###*
 * Number to hex function
 * @param  {int} num    input.
 * @param  {int} length optional length of output. Default to the full length of the input.
 * @return {string}        hex number string.
###
util.toHex = (num, length) ->
  hex = Math.floor(num).toString(16)
  length ?= hex.length

  # Pad output
  for i in [0...length - hex.length]
    hex = "0" + hex

  hex.slice(-length)


###*
 * Map a value [0,1] to [min, max]
 * @param  {float} value a value between 0 and 1 inclusive.
 * @param  {float} min   lowerbound.
 * @param  {float} max   upperbound.
 * @return {float}       mapped value.
###
util.mapValue = (value, min, max) ->
  range = max - min
  value * range + min

GLOBAL.util = util
