import vecmath

type TMaterial* = object
  ambiant*: TVec4f
  diffuse*: TVec4f
  specular*: TVec4f
  shine*: float32
