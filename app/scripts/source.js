function binarySearch (key, array) {

  var low = 0;
  var high = array.length - 1;

  while (low <= high) {

    var mid = Math.floor((low + high) / 2);
    var value = array[mid];

    if (value < key) {
      low = mid + 1;
    } else if (value > key) {
      high = mid - 1;
    } else {
      return mid;
    }

  }
  return -1;
}

var key = 4;
var array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
binarySearch(key, array);