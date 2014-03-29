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
  result.diffuse = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.specular = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.direction = [dir[0], dir[1], dir[2], 0.0'f32]
proc initPointLight*(pos: TVec3f): TPointLight =
  result.diffuse = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.specular = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.position = [pos[0], pos[1], pos[2], 0.0'f32]
