import ecs
import components
import vecmath

proc CollectPointLights*(scene: SceneId, viewMtx: TMat4f): seq[TPointLightRaw] =
  result = @[]
  for i, light, pos in walk(scene, TPointLight, TTransform):
    var plight: TPointLightRaw
    plight.diffuse = light[].diffuse
    plight.specular = light[].specular
    plight.position = mul4v(viewMtx, vec4f(pos[].position, 1))
    plight.cutoff = light[].cutoff
    plight.constant = light[].constant
    plight.linear = light[].linear
    plight.quadratic = light[].quadratic
    result.add(plight)
    

