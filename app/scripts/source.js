var a = 1, b;
for (var i = 0; i < a; i += 1) {
  log(i);
  f();
}

function f(args) {
  var b = 2;
  function f2(args) {
    var c = 2;
    function f3(args) {
      var d = 1;
    }
    for (var i = 0; i < c; i += 1) {
      f3(c);
    }
  }
  for (var j = 0; j < b; j += 1) {
    f2(b);
  }
}

var obj = {
  a: 1,
  b: 2
};


for (key in obj) {
  log(key);
  log(obj[key]);
}
