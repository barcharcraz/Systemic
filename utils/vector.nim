type TVector*[T] = object
  leng: int
  capa: int
  data: ptr T

iterator items*[T](self: TVector[T]): T {.inline.} =
  var i = 0
  while i < self.leng:
    yield self.data.succ(i)
    inc(i)

proc initVector*[T](len: int = 0): TVector[T] =
  var toAlloc = max(10, len)
  result.leng = len
  result.capa = toAlloc
  result.data = cast[ptr T](alloc(sizeof(T)*toAlloc))

proc destroyVector[T](self: TVector[T]) {.destructor.} =
  dealloc(self.data)

proc destroyVector[T: string | ref](self: TVector[T]) {.destructor.} =
  for elm in self:
    GC_unref(elm)
  dealloc(self.data)
proc `[]`[T](self: TVector[T], idx: int): T =
  result = self.data.succ(idx)
proc `[]=`[T](self: var TVector[T], idx: int, val: T) =
  self.data.succ(idx) = val
proc add*[T](self: var TVector[T], item: T) = 
  if self.leng == self.capa:
    self.data = cast[ptr T](realloc(self.data, sizeof(T) * self.capa * 2))
    self.capa *= 2
  self.data.succ(self.leng) = item
  self.leng.inc
  when T is string|ref:
    GC_ref(self.data.succ(self.leng - 1))
  
when isMainModule:
  var vec = initVector[string]()
  vec.add("string1")
  vec.add("string2")
  
