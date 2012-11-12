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

  window.util = util;
})(jQuery, _, Backbone)