import components/camera
import components/transform
import ecs/entity
import ecs/entitynode
import ecs/scene
import ecs/scenenode
import input
import vecmath

proc VelocitySystem*(scene: SceneId; vels: openarray[TComponent[TVelocity]]) {.procvar.} =
  for elm in vels:
    var trans = addr mEntFirst[TTransform](elm.id)
    trans.position = cwiseadd(trans.position, elm.data.lin)
    trans.rotation = mult(trans.rotation, elm.data.rot)


proc MovementSystem*(scene: SceneId; cam: var TComponent[TCamera]) {.procvar.} =
  var inpSys = mEntFirstOpt[TInputMapping](cam.id)
  var pos = mEntFirstOpt[TTransform](cam.id)
  var newVel: TVec3f
  block:
    using inpSys
    if Action("left"): newVel


