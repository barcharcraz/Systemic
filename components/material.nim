import vecmath

type TMaterial* = object
  ambiant*: TVec4f
  diffuse*: TVec4f
  specular*: TVec4f
  shine*: float32

proc initMaterial*(): TMaterial =
  result.ambiant = [0.0'f32, 0.0'f32, 0.0'f32, 1.0'f32]
  result.diffuse = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.specular = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.shine = 1.0'f32
