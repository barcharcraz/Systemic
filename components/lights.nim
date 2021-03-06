import vecmath
import colors
import math
type TLightKind = enum
  lkPoint,
  lkDirectional
type TPointLight* = object
  diffuse*: TVec4f
  specular*: TVec4f
  cutoff*: float32
  constant*: float32
  linear*: float32
  quadratic*: float32
type TDirectionalLight* = object
  diffuse*: TVec4f
  specular*: TVec4f
  direction*: TVec4f
type TSpotLight* = object
  diffuse*: TVec4f
  specular*: TVec4f
  cutoff*: float32
  fov*: float32
type TDirectionalLightRaw* = TDirectionalLight
  ## This is a bit of a stupid type definition, but
  ## have it for consistency, and it will be useful
  ## if there is ever a need for a direction component

type TPointLightRaw* = object
  ## raw point light structure designed
  ## to be sent to the GPU the procedure to
  ## generate thses is in components.nim
  ## since it depends on scene and transform
  ## functionality
  diffuse*: TVec4f
  specular*: TVec4f
  position*: TVec4f
  cutoff*: float32
  constant*: float32
  linear*: float32
  quadratic*: float32
type TSpotLightRaw* = object
  diffuse*: TVec4f
  specular*: TVec4f
  direction*: TVec4f
  position*: TVec4f
  cutoff*: float32
  fov*: float32

type TLight* = TPointLight | TDirectionalLight

proc initDirectionalLight*(dir: TVec3f): TDirectionalLight =
  result.diffuse.data = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.specular.data = [0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32]
  result.direction = vec4f(dir[1], dir[2], dir[3], 0.0'f32)
proc initPointLight*(): TPointLight =
  result.diffuse = vec4f(1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32)
  result.specular = vec4f(0.0'f32, 0.0'f32, 0.0'f32, 0.0'f32)
  result.cutoff = 30'f32
  result.constant = 1.0'f32
  result.linear = 0.0'f32
  result.quadratic = 0.05'f32

proc initPointLight*(color: TColor): TPointLight =
  var (r,g,b) = extractRGB(color)
  result.diffuse = vec4f(r.float32/255.0, g.float32/255.0, b.float32/255.0, 1.0'f32)
  result.specular = vec4f(r.float32/255.0, g.float32/255.0, b.float32/255.0, 1.0'f32)
  result.cutoff = 30'f32
  result.constant = 1.0'f32
  result.linear = 0.0'f32
  result.quadratic = 0.05'f32

proc initSpotLight*(color: TColor): TSpotLight =
  var (r,g,b) = extractRGB(color)
  result.diffuse = vec4f(r.float32/255.0, g.float32/255.0, b.float32/255.0, 1.0'f32)
  result.specular = vec4f(r.float32/255.0, g.float32/255.0, b.float32/255.0, 1.0'f32)
  result.cutoff = 20'f32
  result.fov = 30.0 * (PI / 180.0)