import vecmath
import components
import transform
import mesh
import ecs
type TAxisAlignedBB* = object
  RestAABB*: TAlignedBox3f
  CurAABB*: TAlignedBox3f
MakeEntityComponent(TAxisAlignedBB)
proc initAABB*(initial: TAlignedBox3f): TAxisAlignedBB =
  result = TAxisAlignedBB(RestAABB: initial, CurAABB: initial)
 
proc initAABB*(mesh: TMesh): TAxisAlignedBB =
  for vert in mesh.verts: result.RestAABB.extend(vert.pos)
  result.CurAABB = result.RestAABB

proc UpdateAABBs*(scene: SceneId) {.procvar.} =
  for id, transform, aabb in walk(scene, TTransform, TAxisAlignedBB):
    var mtx = transform[].GenMatrix()
    aabb[].CurAABB = mulArea(aabb[].RestAABB, mtx)
    #if aabb[].CurAABB.max < aabb[].CurAABB.min:
    #  swap(aabb.CurAABB.min, aabb[].CurAABB.max)
