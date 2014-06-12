import vecmath
import mesh
import ecs
import transform
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
   result.CurAABB = result.RestAABB\

proc UpdateAABBs(scene: SceneId) {.procvar.} =
  for id, transform, aabb in walk(scene, TTransform, TAxisAlignedBB):
    var mtx = transform[].GenMatrix()
    var min = vec4f(aabb[].RestAABB.min, 1)
    var max = vec4f(aabb[].RestAABB.max, 1)
    aabb[].CurAABB.min = mul4v(mtx, min)
    aabb[].CurAABB.max = mul4v(mtx, max)
