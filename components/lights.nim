import vecmath
type TLightKind = enum
  lkPoint,
  lkDirectional
type TPointLight* = object
  diffuse*: TVec4f
  specular*: TVec4f
  position*: TVec4f
type TDirectionalLight* = object
  diffuse*: TVec4f
  specular*: TVec4f
  direction*: TVec4f

type TLight* = TPointLight | TDirectionalLight

proc initDirectionalLight*(dir: TVec3f): TDirectionalLight =
  result.diffuse.data = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.specular.data = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.direction = vec4f(dir[1], dir[2], dir[3], 0.0'f32)
proc initPointLight*(pos: TVec3f): TPointLight =
  result.diffuse = vec4f(1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32)
  result.specular = vec4f(1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32)
  result.position = vec4f(pos[1], pos[2], pos[3], 1.0'f32)
