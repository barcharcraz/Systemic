import linagl
import math
type TCamera* = TMat4

proc initCamera(float32 near; float32 far; float32 fov): TCamera =
  var m33 = ((far + near) / (far - near))
  var m34 = ((far * near) / (far - near))
  var scale = (1 / tan(fov * 0.5 * (PI / 180)))
  result = [
