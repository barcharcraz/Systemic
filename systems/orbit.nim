import ecs
import components
import vecmath
proc OrbitSystem*(scene: SceneId) {.procvar.} =
  for id, trans, vel, o in walk(scene, TTransform, TVelocity, TOrbit):
    var transform = entFirst[TTransform](o[].around)
    var newVel = trans[].position - transform.position
    newVel = (newVel / newVel.norm()) * o[].vel
    vel[].lin = newVel * -1
    echo cast[int](vel)
