import ecs
import components
import vecmath
proc OrbitSystem*(scene: SceneId) {.procvar.} =
  for id, trans, acc, o in walk(scene, TTransform, TAcceleration, TOrbit):
    var transform = entFirst[TTransform](o[].around)
    var newVel = trans[].position - transform.position
    newVel = (newVel / newVel.norm()) * o[].vel
    echo "orbit run"
    acc[].lin = newVel * -1
