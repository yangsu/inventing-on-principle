(function() {
  var Pos = CodeMirror.Pos;

  function forEach(arr, f) {
    for (var i = 0, e = arr.length; i < e; ++i) f(arr[i]);
  }

  function arrayContains(arr, item) {
    if (!Array.prototype.indexOf) {
      var i = arr.length;
      while (i--) {
        if (arr[i] === item) {
          return true;
        }
      }
      return false;
    }
    return arr.indexOf(item) != -1;
  }

  function scriptHint(editor, keywords, getToken, options) {
    // Find the token at the cursor
    var cur = editor.getCursor(),
        token = getToken(editor, cur),
        tprop = token;
    return {
      list: getCompletions(token, context, keywords, options),
      from: Pos(cur.line, token.start),
      to: Pos(cur.line, token.end)
    };
  }

  CodeMirror.processingHint = function(editor, options) {
    return scriptHint(editor, processingKeywards, function(e, cur) {
      return e.getTokenAt(cur);
    }, options);
  };

  var storageKeywords = 'this|super|class|interface|void|color|string|byte|short|char|int|long|float|double|boolean|private|protected|public|abstract|final|native|static|transient|synchronized|volatile|strictfp|extends|implements'.split('|');
  var controlKeywords = 'try|catch|finally|throw|return|break|case|continue|default|do|while|for|switch|if|else|import|new|package|throws|instanceof'.split('|');
  var constantsKeywords = 'false|null|true|focused|frameCount|frameRate|height|height|key|keyCode|keyPressed|mouseButton|mousePressed|mouseX|mouseY|online|pixels|pmouseX|pmouseY|screen|width|ADD|ALIGN_CENTER|ALIGN_LEFT|ALIGN_RIGHT|ALPHA|ALPHA_MASK|ALT|AMBIENT|ARGB|ARROW|BACKSPACE|BEVEL|BLEND|BLEND|BLUE_MASK|BLUR|CENTER|CENTER_RADIUS|CHATTER|CODED|COMPLAINT|COMPONENT|COMPOSITE|CONCAVE_POLYGON|CONTROL|CONVEX_POLYGON|CORNER|CORNERS|CROSS|CUSTOM|DARKEST|DEGREES|DEG_TO_RAD|DELETE|DIFFERENCE|DIFFUSE|DISABLED|DISABLE_TEXT_SMOOTH|DOWN|ENTER|EPSILON|ESC|GIF|GREEN_MASK|GREY|HALF|HALF_PI|HALF_PI|HAND|HARD_LIGHT|HSB|IMAGE|INVERT|JAVA2D|JPEG|LEFT|LIGHTEST|LINES|LINE_LOOP|LINE_STRIP|MAX_FLOAT|MITER|MODEL|MOVE|MULTIPLY|NORMALIZED|NO_DEPTH_TEST|NTSC|ONE|OPAQUE|OPENGL|ORTHOGRAPHIC|OVERLAY|P2D|P3D|PAL|PERSPECTIVE|PI|PI|PIXEL_CENTER|POINTS|POLYGON|POSTERIZE|PROBLEM|PROJECT|QUADS|QUAD_STRIP|QUARTER_PI|RADIANS|RAD_TO_DEG|RED_MASK|REPLACE|RETURN|RGB|RIGHT|ROUND|SCREEN|SECAM|SHIFT|SOFT_LIGHT|SPECULAR|SQUARE|SUBTRACT|SVIDEO|TAB|TARGA|TEXT|TFF|THIRD_PI|THRESHOLD|TIFF|TRIANGLES|TRIANGLE_FAN|TRIANGLE_STRIP|TUNER|TWO|TWO_PI|TWO_PI|UP|WAIT|WHITESPACE'.split('|');
  var classKeywords = 'Array|Character|Integer|Math|Object|PFont|PImage|PSound|StringBuffer|Thread'.split('|');
  var functionsKeywords = 'abs|acos|alpha|alpha|ambient|ambientLight|append|applyMatrix|arc|asin|atan2|atan|background|beginCamera|beginShape|bezier|bezierDetail|bezierPoint|bezierTangent|bezierVertex|binary|blend|blend|blue|boolean|box|brightness|byte|cache|camera|ceil|char|charAt|color|colorMode|concat|constrain|contract|copy|copy|cos|createFont|cursor|curve|curveDetail|curvePoint|curveSegments|curveTightness|curveVertex|day|degrees|delay|directionalLight|dist|duration|ellipse|ellipseMode|emissive|endCamera|endShape|equals|exp|expand|fill|filter|filter|float|floor|framerate|frustum|get|get|green|hex|hint|hour|hue|image|imageMode|indexOf|int|join|keyPressed|keyReleased|length|lerp|lightFalloff|lightSpecular|lights|line|link|list|loadBytes|loadFont|loadImage|loadPixels|loadSound|loadStrings|log|lookat|loop|loop|mag|mask|max|millis|min|minute|modelX|modelY|modelZ|month|mouseDragged|mouseMoved|mousePressed|mouseReleased|nf|nfc|nfp|nfs|noCursor|noFill|noLoop|noLoop|noSmooth|noStroke|noTint|noise|noiseDetail|noiseSeed|normal|open|openStream|ortho|param|pause|perspective|play|point|pointLight|popMatrix|pow|print|printCamera|printMatrix|printProjection|println|pushMatrix|quad|radians|random|randomSeed|rect|rectMode|red|redraw|resetMatrix|reverse|rotate|rotateX|rotateY|rotateZ|round|saturation|save|saveBytes|saveFrame|saveStrings|scale|screenX|screenY|screenZ|second|set|set|shininess|shorten|sin|size|smooth|sort|specular|sphere|sphereDetail|splice|split|spotLight|sq|sqrt|status|stop|str|stroke|strokeCap|strokeJoin|strokeWeight|subset|substring|switch|tan|text|textAlign|textAscent|textDescent|textFont|textLeading|textMode|textSize|textWidth|texture|textureMode|time|tint|toLowerCase|toUpperCase|translate|triangle|trim|unHint|unbinary|unhex|updatePixels|vertex|volume|year|draw|setup'.split('|');

  var processingKeywards = storageKeywords.concat(controlKeywords).concat(constantsKeywords).concat(classKeywords).concat(functionsKeywords);

  function getCompletions(token, context, keywords, options) {
    var found = [],
        start = token.string;

    function maybeAdd(str) {
      if (str.indexOf(start) == 0 && !arrayContains(found, str)) found.push(str);
    }
    forEach(keywords, maybeAdd);
    return found;
  }
})();
