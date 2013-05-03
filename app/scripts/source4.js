function swap(array, a, b) {
  var tmp = array[a];
  array[a] = array[b];
  array[b] = tmp;
}

function insert(array, begin, end, v) {
  while (begin + 1 < end && array[begin + 1] < v) {
    swap(array, begin, begin + 1);
    ++begin;
  }
  array[begin] = v;
}

function merge_inplace(array, begin, middle, end) {
  for (; begin < middle; ++begin) {
    if (array[begin] > array[middle]) {
      var v = array[begin];
      array[begin] = array[middle];
      insert(array, middle, end, v);
    }
  }
}

function msort(array, begin, end) {
  var size = end - begin;
  if (size < 2) {
    return;
  }

  var middle = begin + Math.floor(size / 2);

  msort(array, begin, middle);
  msort(array, middle, end);
  merge_inplace(array, begin, middle, end);
}

var input = _.shuffle(_.range(0, 100));
msort(input, 0, input.length);
