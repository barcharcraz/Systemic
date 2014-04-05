import vecmath

type TMaterial* = object
  ambiant*: TVec4f
  diffuse*: TVec4f
  specular*: TVec4f
  shine*: float32

proc initMaterial*(): TMaterial =
  result.ambiant.data = [0.0'f32, 0.0'f32, 0.0'f32, 1.0'f32]
  result.diffuse.data = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.specular.data = [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32]
  result.shine = 10.0'f32
