import ecs
import components
import genutils
import vecmath
import utils/iterators
proc BruteForceFrustum*(scene: SceneId): TAlignedBox3f =
  ## find a bounding box for objects in the frustum by
  ## brute force, this is totally not worth it, but is
  ## good for debugging other culling schemes or for 
  ## stuff that is not really for speed but still needs
  ## this bbox
  var (camEnt, cam, camTrans) = first(walk(scene, TCamera, TTransform))
  var viewMtx = camTrans[].GenRotTransMatrix().AdjustViewMatrix()
  var projMtx = cam[].matrix.AdjustProjMatrix()
  var vp = mul(projMtx, viewMtx)
  for id, aabb in walk(scene, TAxisAlignedBB):
    if frustumContains(vp, aabb[].CurAABB):
      if result.max == result.min:
        result = aabb[].CurAABB
      else:
        result.extend(aabb[].CurAABB)


