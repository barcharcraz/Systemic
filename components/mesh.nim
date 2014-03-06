import vecmath
type TVertex* = object
  pos: TVec4f
  norm: TVec4f
  uv: TVec2f
type TMesh* = object
  verts: seq[TVertex]
  indices: seq[uint]

