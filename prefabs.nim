import components
import ecs
import assetloader
import vecmath
proc addStaticMesh*(scene: SceneId, model, texture: string, pos: TVec3f): EntityId {.discardable.} =
  result = genEntity()
  scene.add(result)
  result.add(loadMesh(model))
  result.add(getTexture(texture))
  result.add(initMaterial())
  result.add(initTransform(pos))
proc addCamera*(scene: SceneId, pos: TVec3f = vec3f(0,0,0)): EntityId {.discardable} =
  result = genEntity()
  scene.add(result)
  result.add(initCamera())
  result.add(initTransform(pos))
  result.add(initVelocity(vkPre))
  
  
