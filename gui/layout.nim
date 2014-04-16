import vecmath

type CLayoutElm* = generic x
  x.pos is TVec2f
  x.size is TVec2f

type TLayoutElm* = object
  obj: ref TObject
  pos*: proc(): var TVec2f
  size*: proc(): var TVec2f

converter mkLayoutElm*(x: ref CLayoutElm): TLayoutElm =
  result.obj = x
  result.pos = proc(): var TVec2f = x.pos
  result.size = proc(): var TVec2f = x.size
