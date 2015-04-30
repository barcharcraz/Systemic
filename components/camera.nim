import vecmath
import math
type TCamera* = object
  matrix*: TMat4f
  near*: float
  far*: float
  fov: float
  aspect: float


proc initCamera*(near, far, fov, aspect: float32): TCamera =
  result.fov = fov
  result.near = near
  result.far = far
  result.aspect = aspect
  var m33 = ((far + near) / (far - near))
  var m34 = ((far * near) / (far - near))
  var scale = (1 / tan(fov * 0.5 * (PI / 180)))
  result.matrix.data = [scale.float32 * aspect, 0'f32,     0'f32,     0'f32,
            0'f32,     scale.float32, 0'f32,     0'f32,
            0'f32,     0'f32,     -m33.float32, -1'f32,
            0'f32,     0'f32,     -m34.float32,    0'f32]

proc initCamera*(): TCamera = initCamera(1, 100, 60, 1.0/1.0)
proc initCamera*(near, far: float32): TCamera = initCamera(near, far, 60, 16.0/9.0)
proc initCamera*(fov: float32): TCamera = initCamera(1, 100, fov, 16.0/9.0)

type TFrustumCorner* = enum
  fcNearUL,
  fcNearUR,
  fcNearBL,
  fcNearBR,
  fcFarUL,
  fcFarUR,
  fcFarBL,
  fcFarBR
proc FrustumCorner*(camera: TCamera, which: TFrustumCorner): TVec3f =
  var rfov = camera.fov * (PI / 180.0)
  var hfar = 2 * tan(rfov / 2) * camera.far
  var hnear = 2 * tan(rfov / 2) * camera.near
  var wfar = hfar * camera.aspect
  var wnear = hnear * camera.aspect
  case which
  of fcNearUL:
    result.z = -camera.near
    result.y = hnear / 2
    result.x = -wnear / 2
  of fcNearUR:
    result.z = -camera.near
    result.y = hnear / 2
    result.x = wnear / 2
  of fcNearBL:
    result.z = -camera.near
    result.y = -hnear / 2
    result.x = -wnear / 2
  of fcNearBR:
    result.z = -camera.near
    result.y = -hnear / 2
    result.x = wnear / 2
  of fcFarUL:
    result.z = -camera.far
    result.y = hfar / 2
    result.x = -wfar / 2
  of fcFarUR:
    result.z = -camera.far
    result.y = hfar / 2
    result.x = wfar / 2
  of fcFarBL:
    result.z = -camera.far
    result.y = -hfar / 2
    result.x = -wfar / 2
  of fcFarBR:
    result.z = -camera.far
    result.y = -hfar / 2
    result.x = wfar / 2 

