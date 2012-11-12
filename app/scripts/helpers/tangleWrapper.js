(function (jQuery, _, Backbone, Tangle) {

var passthrough = function (value) { return value; };

window.genTangle = function (selector, defaults, update) {
  var tangle = new Tangle ($(selector).get(0), {
    initialize: function () {
      var self = this;
      _.each(defaults, function (value, key) {
        self[key] = value;
      });
    },
    update: update
  });
  return tangle;
};


}(jQuery, _, Backbone, Tangle));