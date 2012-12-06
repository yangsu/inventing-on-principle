(function (jQuery, _, Backbone) {
  var util = {};

  /**
   * Special handling for regular expression literal since we need to
   * convert it to a string literal, otherwise it will be decoded
   * as object "{}" and the regular expression would be lost.
   */
  util.adjustRegexLiteral = function (key, value) {
    if (key === 'value' && value instanceof RegExp) {
      value = value.toString();
    }
    return value;
  };

  /**
   * Convert codeMirror location object to 0 based index for lines
   * @param  {Location Object} loc has both 'line' and 'ch' positions
   * @return {Location Object}     normalized location
   */
  util.convertLoc = function (loc) {
    return {
      line: loc.line - 1,
      ch:   loc.column
    };
  };

  /**
   * Test to see if a position is within a codeMirror Range array
   * @param  {int} pos   position
   * @param  {array} range (range[0], range[1])
   * @return {boolean}       true if pos is within range, false otherwise
   */
  util.withinRange = function (pos, range) {
    return range && range.length === 2 && pos >= range[0] && pos <= range[1];
  };

  /**
   * Number to hex function
   * @param  {int} num    input
   * @param  {int} length optional length of output. Default to the full length of the input
   * @return {string}        hex number string
   */
  util.toHex = function (num, length) {
    var hex = Math.floor(num).toString(16);
    length = (length || hex.length);
    // Pad output
    for (var i = 0, l = length - hex.length; i < l; i += 1) {
      hex = '0' + hex;
    }
    return hex.slice(-length);
  }

  window.util = util;
})(jQuery, _, Backbone)