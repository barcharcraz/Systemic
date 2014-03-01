import vecmath
import math
type TCamera* = TMat4f

proc initCamera*(near, far, fov: float32): TCamera =
  var m33 = ((far + near) / (far - near))
  var m34 = ((far * near) / (far - near))
  var scale = (1 / tan(fov * 0.5 * (PI / 180)))
  result = [scale.float32, 0'f32,     0'f32,     0'f32,
            0'f32,     scale.float32, 0'f32,     0'f32,
            0'f32,     0'f32,     -m33.float32, -m34.float32,
            0'f32,     0'f32,     -1'f32,    0'f32]

proc initCamera*(): TCamera = initCamera(1, 100, 60)
proc initCamera*(near, far: float32): TCamera = initCamera(near, far, 60)
proc initCamera*(fov: float32): TCamera = initCamera(1, 100, fov)
