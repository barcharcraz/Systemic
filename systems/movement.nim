import components
import utils/log
import ecs/entity
import ecs/entitynode
import ecs/scene
import ecs/scenenode
import utils/iterators
import input
import vecmath
import gametime
const movementDbg = false
loggingWrapper(movementDbg)
proc VelocitySystem*(scene: SceneId) {.procvar.} =
  for id, elm in walk(scene, TVelocity):
    var trans = id?TTransform
    trans[].position = trans.position + TVelocity(elm[]).lin
    case elm[].kind
    of vkPre: trans[].rotation = mul(elm[].rot, trans[].rotation)
    of vkPost: trans[].rotation = mul(trans[].rotation, elm[].rot)

proc AccelerationSystem*(scene: SceneId) {.procvar.} =
  for id, vel, acc in walk(scene, TVelocity, TAcceleration):
    vel.lin = vel.lin + acc.lin
    vel.rot = mul(vel.rot, acc.rot)


proc MovementSystem*(scene: SceneId; inp: TInputMapping) {.procvar.} =
  var (cam, camMtx, pos, vel) = first(walk(scene, TCamera, TTransform, TVelocity))
  var newPos: TVec3f
  var dt = GetFrameTime()
  var rotX = inp.mouse.dx * 0.1 * dt
  var rotY = inp.mouse.dy * 0.1 * dt
  var newRotX = quatFromAngleAxis(rotX, vec3f(0,1,0))
  var newRotY = quatFromAngleAxis(rotY, vec3f(1,0,0))
  var newRot = identityQuatf()
  # what we have here is a First person shooter style camera, 
  # that is side to side movements rotate around the world UP
  # direction, while up and down movements rotate around the left/right
  # direction OF THE CAMERA
  # so we let q = the old rotation and do
  # q_new = q * rx * q'
  newRot = mul(conj(pos[].rotation), newRot)
  newRot = mul(newRotX, newRot)
  newRot = mul(pos[].rotation, newRot)
  newRot = mul(newRot, newRotY)
  newRot = newRot / norm(newRot)
  block:
    using inp
    if Action("left"): newPos += vec3f(-1,0,0)
    if Action("right"): newPos += vec3f(1,0,0)
    if Action("up"): newPos += vec3f(0,1,0)
    if Action("down"): newPos += vec3f(0,-1,0)
    if Action("forward"): newPos += vec3f(0,0,-1)
    if Action("backward"): newPos += vec3f(0,0,1)
  #we are multiplying by the inverse of the current rotation
  #but since the rotation matrix is orthogonal we just transpose
  #it
  newPos = newPos * dt * 10
  newPos = mulv(pos[].rotation.toRotMatrix().transpose(), newPos)
  pos[].position += newPos
  pos[].rotation = mul(newRot, pos[].rotation)



proc OrbitMovementSystem*(scene: SceneId, dx, dy: float, pos: TVec3f) =
  var xrot = quatFromAngleAxis(dx * 0.005, vec3f(0,1,0))
  #var yrot = quatFromAngleAxis(dy * 0.005, vec3f(-1,0,0))
  #var rot = mul(yrot, xrot)
  for id, cam, view in walk(scene, TCamera, TTransform):
    
    view[].position = view[].position - pos
    var yrot = quatFromAngleAxis(dy * 0.005, normalize(cross(vec3f(0,1,0), view[].position)))
    var rot = mul(xrot, yrot)
    debug(formatVec3f(view[].position))
    rot = normalize(rot)
    view[].position = mulv(toRotMatrix(rot), view[].position)
    view[].position = view[].position + pos
    #debug(formatVec3f(view[].position))
    rot.i = -rot.i
    rot.j = -rot.j
    rot.k = -rot.k
    view[].rotation = mul(view[].rotation, rot)

proc OrbitMovementSystem*(scene: SceneId, imp: TInputMapping, pos: TVec3f) =
  OrbitMovementSystem(scene, imp.mouse.dx, imp.mouse.dy, pos)

proc OrbitSelectionMovement*(scene: SceneId, dx, dy: float) =
  for id, sel, transform in walk(scene, TSelected, TTransform):
    OrbitMovementSystem(scene, dx, dy, transform[].position)

proc OrbitSelectionMovement*(scene: SceneId, imp: TInputMapping) =
  OrbitSelectionMovement(scene, imp.mouse.dx, imp.mouse.dy)

proc EditorMovementSystem*(scene: SceneId, imp: TInputMapping, editorActive: bool) =
  if editorActive:
    OrbitSelectionMovement(scene, imp)
  else:
    MovementSystem(scene, imp)