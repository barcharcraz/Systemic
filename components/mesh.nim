import vecmath
type TVertex* = object
  pos*: TVec3f
  norm*: TVec3f
  uv*: TVec2f
proc initVertex*(pos: TVec3f): TVertex =
  ##initialize a vertex with default values
  ##(of zero) for the normal and UV
  result.pos[0] = pos[0]
  result.pos[1] = pos[1]
  result.pos[2] = pos[2]
  #norm and UV are initialized to zero
type TMesh* = object
  verts*: seq[TVertex]
  indices*: seq[uint32]

