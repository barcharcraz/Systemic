import vecmath
import utils/log
import opengl
import rendering/glcore
import rendering/genutils
import ecs
import components
import strutils
import components/selectDat
import utils/iterators
import input
const selectionDbg = true
loggingWrapper(selectionDbg)


proc findSelected(scene: SceneId, x,y: float, mtx: TMat4f): EntityId =
  var viewport: TVec4f
  glGetFloatv(cGL_VIEWPORT, addr viewport.data[0])
  var (camId, cam, camTrans) = first(walk(scene, TCamera, TTransform))
  var ray = TRay(origin: camTrans[].position, dir: vec3f(x, viewport[4] - y, 1))
  #if depth >= 0.99999'f32: return (-1).EntityId
  #ray.origin = unProject(ray.origin, mtx, viewport)
  debug("RAY ORIGIN: " & formatVec3f(ray.origin))
  ray.dir = unProject(ray.dir, mtx, viewport)
  ray.dir = ray.dir - ray.origin
  ray.dir = normalize(ray.dir)
  debug("RAY DIRECTION: " & formatVec3f(ray.dir))
  var preComputed = Precompute_Ray(ray)
  for i, aabb in walk(scene, TAxisAlignedBB):
    if intersects(preComputed, aabb[].CurAABB):
      return i
  return (-1).EntityId
proc handleSelectionAttempt*(scene: SceneId, x,y: float) =
  var (camId, cam, camTrans) = first(walk(scene, TCamera, TTransform))
  var viewMtx = camTrans[].GenRotTransMatrix().AdjustViewMatrix()
  var projMtx = cam[].matrix.AdjustProjMatrix()
  var selected = findSelected(scene, x, y, mul(projMtx, viewMtx))
  clear(scene, TSelected)
  if selected != (-1).EntityId: selected.add(initSelected())
  debug("Selected Entity: " & $selected.int)
  if selected == (-1).EntityId: return
  var callbck = selected?onMouseDown
  if callbck != nil: callbck[](x,y)
 
proc SelectionSystem*(scene: SceneId, inp: TInputMapping) =
  if Action(inp, "select"):
    handleSelectionAttempt(scene, inp.mouse.x, inp.mouse.y)
