function insertionSort(list) {
  var key, i;
  for (var j = 1; j < list.length; j++) {
    key = list[j];
    i = j - 1;
    while ((i >= 0) && (list[i] > key)) {
      list[i + 1] = list[i];
      i = i - 1;
    }
    list[i + 1] = key;
  }
  return list;
}

var input = _.shuffle(_.range(0, 15));
insertionSort(input);
