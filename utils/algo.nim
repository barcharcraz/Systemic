

proc lowerBound*[T](a: openarray[T], key: T, cmp: proc(x,y: T): int {.closure.}): int =
  result = a.low
  var pos = result
  var count, step: int
  count = a.high - a.low + 1
  while count != 0:
    pos = result
    step = count div 2
    pos += step
    if cmp(a[pos], key) < 0:
      pos.inc
      result = pos
      count -= step + 1
    else:
      count = step
proc lowerBound*[T](a: openarray[T], key: T): int = lowerBound(a, key, system.cmp[T])
when isMainModule:
  import unittest
  test "simple1":
    var arr = [1,3,4,5,6,10]
    var insertPos = lowerBound(arr, 2, system.cmp[int])
    check(insertPos == 1)
  test "simple2":
    var arr = @[1,3,4,5,6,10]
    var insertPos = lowerBound(arr, 11, system.cmp[int])
    check(insertPos == 6)
  test "simple3":
    var arr = @[1,2,3,4,6]
    var insertPos = lowerBound(arr, 5)
    check(insertPos == 4)
  doAssert lowerBound([1,2,4], 3, system.cmp[int]) == 2
  doAssert lowerBound([1,2,2,3], 4, system.cmp[int]) == 4