import ecs
import math
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
proc CollectDirLights*(scene: SceneId, viewMtx: TMat4f): seq[TDirectionalLightRaw] =
  result = @[]
  for i, light in walk(scene, TDirectionalLight):
    var dlight: TDirectionalLightRaw
    dlight.diffuse = light[].diffuse
    dlight.specular = light[].specular
    dlight.direction = mul4v(viewMtx, light[].direction)
    result.add(dlight)
    
proc CalcViewMatrix*(dir: TVec3f): TMat4f =
  # this could be a useful function for vecmath
  var dir = normalize(dir)
  var angle = arccos(dot(dir, vec3f(0,0,-1)))
  if angle == 0: return identity4f()
  var axis = normalize(cross(dir, vec3f(0,0,-1)))
  var quat = quatFromAngleAxis(angle, axis)
  quat = normalize(quat)
  result = quat.toRotMatrix().toAffine()

let BiasMatrix* = TMat4f(data: [0.5'f32, 0.0, 0.0, 0.0,
                                  0.0, 0.5, 0.0, 0.0,
                                  0.0, 0.0, 0.5, 0.0,
                                  0.5, 0.5, 0.5, 1.0])
let DefaultDirProj = CreateOrthoMatrix(vec3f(-20, -20, 20), vec3f(20,20,-20))
proc ConstructDirShadowMatrices*(camera: TCamera, dir: TVec3f): tuple[view, proj: TMat4f] =
  var corners: array[TFrustumCorner, TVec3f]
  for elm in TFrustumCorner:
    corners[elm] =  FrustumCorner(camera, elm)
  var centroid = sum(corners) / len(corners).float32
  system.
proc ConstructDepthVP*(dir: TVec3f, proj: TMat4f): TMat4f =
  var view = CalcViewMatrix(dir)
  var vp = mul(proj, view)
  result = mul(BiasMatrix, vp)
proc ConstructDirDepthVP*(dir: TVec3f): TMat4f =
  result = ConstructDepthVP(dir, DefaultDirProj)

proc AdjustViewMatrix*(mat: TMat4f): TMat4f =
  result = mat
  result[1,4] = result[1,4] * -1
  result[2,4] = result[2,4] * -1
  result[3,4] = result[3,4] * -1
proc AdjustProjMatrix*(mat: TMat4f): TMat4f =
  result = mat
  result[3,4] = result[3,4] * 2