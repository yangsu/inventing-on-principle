var a = 10;
for (var i = 0; i < a; i += 1) {
  log(i);
  f();
}

function f (args) {
  var b = 10;
  function f2 (args) {
    var c= 10;
    function f3 (args) {
      var d = 10;
    }
    for (var i = 0; i < c; i += 1) {
      f3(c);
    }
  }
  for (var j = 0; j < b; j += 1) {
    f2(b);
  }
}