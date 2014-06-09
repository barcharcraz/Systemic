import vecmath
import mesh
type TAxisAlignedBB* = object
  RestAABB: TAlignedBox3f
  CurAABB: TAlignedBox3f

proc initAABB*(initial: TAlignedBox3f): TAxisAlignedBB =
  result = TAxisAlignedBB(RestAABB: initial, CurAABB: initial)
 
proc initAABB*(mesh: TMesh): TAxisAlignedBB =
  for vert in mesh.verts:
    if vert.pos < result.RestAABB.min:
      result.RestAABB.min = vert.pos
    if vert.pos > result.RestAABB.max:
      result.RestAABB.max = vert.pos
   result.CurAABB = result.RestAABB
