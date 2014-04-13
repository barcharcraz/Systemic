
proc new*[T](x: T): ref T =
  new(result)
  result[] = x
