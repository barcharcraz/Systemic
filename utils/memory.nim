
proc new*[T](x: T): ref T =
  new(result)
  result[] = x

proc BitScanForward64*(Index: ptr uint32, Mask: int64) 
  {.header:"<intrin.h>", importc: "_BitScanForward64".}