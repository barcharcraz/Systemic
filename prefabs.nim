import components
import ecs
import assetloader
import vecmath
import colors
proc addStaticMesh*(scene: SceneId, model, texture: string, pos: TVec3f): EntityId {.discardable.} =
  result = genEntity()
  scene.add(result)
  var mesh = loadMesh(model)
  result.add(mesh)
  result.add(getTexture(texture))
  result.add(initMaterial())
  result.add(initTransform(pos))
  result.add(initAABB(mesh))
proc addCamera*(scene: SceneId, pos: TVec3f = vec3f(0,0,0)): EntityId {.discardable} =
  result = genEntity()
  scene.add(result)
  result.add(initCamera())
  result.add(initTransform(pos))
  result.add(initVelocity(vkPre))
proc addDirectionalLight*(scene: SceneId; dir: TVec3f): EntityId {.discardable.} =
  result = genEntity()
  scene.add(result)
  result.add(initDirectionalLight(dir))
proc addPointLight*(scene: SceneId; pos: TVec3f): EntityId {.discardable.} =
  result = genEntity()
  scene.add(result)
  result.add(initPointLight())
  result.add(initTransform(pos))
proc addPointLight*(scene: SceneId, pos: TVec3f, color: TColor): EntityId {.discardable.} =
  result = genEntity()
  scene.add(result)
  result.add(initPointLight(color))
  result.add(initTransform(pos))
proc addSpotLight*(scene: SceneId, pos, dir: TVec3f, color: TColor): EntityId {.discardable.} =
  result = genEntity()
  scene.add(result)
  result.add(initTransform(pos, quatFromTwoVectors(vec3f(0,1,0), dir)))
  result.add(initSpotLight(color))

