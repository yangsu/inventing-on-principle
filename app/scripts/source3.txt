var memoTable = {};

function memoizedFib(n) {
  if (n <= 2) {
    return 1;
  }

  if (n in memoTable) {
    return memoTable[n];
  }

  memoTable[n] = memoizedFib(n - 1) + memoizedFib(n - 2);
  return memoTable[n];
}


var res = memoizedFib(10);