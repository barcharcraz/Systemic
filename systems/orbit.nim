import ecs
import components
import vecmath
proc OrbitSystem*(scene: SceneId) {.procvar.} =
  for id, trans, acc, o in walk(scene, TTransform, TAcceleration, TOrbit):
    var transform = o[].around?TTransform
    var newVel = trans[].position - transform.position
    newVel = (newVel / newVel.norm()) * o[].vel
    acc[].lin = newVel * -1
