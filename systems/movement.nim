import components
import utils/log
import ecs/entity
import ecs/entitynode
import ecs/scene
import ecs/scenenode
import input
import vecmath
const movementDbg = true
loggingWrapper(movementDbg)
proc VelocitySystem*(scene: SceneId) {.procvar.} =
  for id, elm in walk(scene, TVelocity):
    var trans = addr mEntFirst[TTransform](id)
    trans.position = trans[].position + elm[].lin
    trans.rotation = mul(trans[].rotation, elm[].rot)
  for id, elm in walk(scene, TPremulVelocity):
    var trans = addr mEntFirst[TTransform](id)
    trans.position = trans.position + TVelocity(elm[]).lin
    trans.rotation = mul(TVelocity(elm[]).rot, trans.rotation)

proc AccelerationSystem*(scene: SceneId) {.procvar.} =
  for id, vel, acc in walk(scene, TVelocity, TAcceleration):
    vel.lin = vel.lin + acc.lin
    vel.rot = mul(vel.rot, acc.rot)
proc MovementSystem*(scene: SceneId; cam: var TComponent[TCamera]) {.procvar.} =
  var pInpSys = mEntFirstOpt[ptr TInputMapping](cam.id)
  if pInpSys == nil: return
  var inpSys = pInpSys[][]

  var pos = mEntFirstOpt[TTransform](cam.id)
  var vel = (ptr TVelocity)(mEntFirstOpt[TPremulVelocity](cam.id))
  var newVel: TVec3f
  var rotX = inpSys.AxisAction("mouseX")
  var rotY = inpSys.AxisAction("mouseY")
  var newRotX = quatFromAngleAxis(rotX, vec3f(0,1,0))
  var newRotY = quatFromAngleAxis(rotY, vec3f(1,0,0))
  var newRot = identityQuatf()
  newRot = mul(newRot, newRotX)
  newRot = mul(newRot, newRotY)
  block:
    using inpSys
    if Action("left"): newVel += vec3f(-1,0,0)
    if Action("right"): newVel += vec3f(1,0,0)
    if Action("up"): newVel += vec3f(0,1,0)
    if Action("down"): newVel += vec3f(0,-1,0)
    if Action("forward"): newVel += vec3f(0,0,-1)
    if Action("backward"): newVel += vec3f(0,0,1)
  #we are multiplying by the inverse of the current rotation
  #but since the rotation matrix is orthogonal we just transpose
  #it
  newVel = mulv(pos[].rotation.toRotMatrix().transpose(), newVel)
  if vel != nil:
    vel[].lin = newVel
    vel[].rot = newRot
  
proc OrbitMovementSystem*(scene: SceneId, dx, dy: float, pos: TVec3f) =
  var xrot = quatFromAngleAxis(dx * 0.005, vec3f(0,1,0))
  var yrot = quatFromAngleAxis(dy * 0.005, vec3f(-1,0,0))
  var rot = mul(xrot, yrot)
  for id, cam, view in walk(scene, TCamera, TTransform):
    var newPos = mulv(toRotMatrix(rot), (view[].position - pos))
    newPos = newPos + pos
    rot.i = -rot.i
    rot.j = -rot.j
    rot.k = -rot.k
    view[].rotation = mul(view[].rotation, rot)
    view[].position = newPos
  
proc OrbitSelectionMovement*(scene: SceneId, dx, dy: float) =
  for id, sel, transform in walk(scene, TSelected, TTransform):
    OrbitMovementSystem(scene, dx, dy, transform[].position)
