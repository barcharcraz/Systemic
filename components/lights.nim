import linagl
type TLightKind = enum
  lkPoint,
  lkDirectional
type TPointLight = object
  diffuse: TVec4f
  specular: TVec4f
  position: TVec4f
type TDirectionalLight = object
  diffuse: TVec4f
  specular: TVec4f
  position: TVec4f

type TLight = TPointLight | TDirectionalLight

