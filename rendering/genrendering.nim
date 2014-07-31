
type TRenderingBackend* = enum
  rbDirect3D,
  rbOpenGL
const backend = rbOpenGL
when backend == rbOpenGL:
  type TBundle* = object


