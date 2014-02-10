import linagl/vector
#import linagl/matrix
import ecs/Scene
import ecs/SceneNode
import math

type TSphere = object
  center: TVec3
  radius: float
type TLight = object
  pos: TVec3
  diffuse: TVec3
proc initSphere(): TSphere = 
  result = TSphere(center:[0.0'f32,0.0'f32,0.0'f32], radius: 0.0)
proc findIntersection(ray: TVec3, eye: TVec3, sphere: TSphere): float =
  var toEye = -1.0'f32 *(sphere.center - eye)
  var dist = ray *. ray
  var quadratic = (pow((2.0'f32 * toEye) *. ray, 2) - (4*pow(dist,2)*((toEye *. toEye) - pow(sphere.radius, 2))))
  if quadratic < 0:
    return -1.0
  else:
    var c = (-2.0'f32 * toEye) *. ray
    var sq = sqrt(quadratic)
    var tpos = (c + sq) / (2 * pow(dist, 2))
    var tmin = (c - sq) / (2 * pow(dist, 2))
    var t = min(tpos, tmin)
    return t
  
proc findIntersectionPoint(ray: TVec3, eye: TVec3, sphere: TSphere): TVec3 = 
  result = ray * findIntersection(ray, eye, sphere)
proc GetDiffuseColor(inter: TVec3, obj: TSphere, light: TLight): TVec3 =
  var toLight = inter - light.pos
  var norm = inter - obj.center
  var toLightN = toLight.normalized()
  norm = norm.normalized()
  var ndl: float = toLightN *. norm
  result = ndl.float32 * light.diffuse
proc GetColor(Ray: TVec3, eye: TVec3, sphere: TSphere, light: TLight): TVec3 =
  var obj = initSphere()
  var intersection = findIntersectionPoint(ray, eye, sphere)
  var diffuseColor: TVec3 = GetDiffuseColor(intersection, sphere, light)
  result = diffuseColor
  
proc getWindowBounds(fov: float, aspect: float): tuple[bl, tr: TVec3] = 
  result.bl = [0.0'f32,0.0'f32,0.0'f32].TVec3
  result.tr = [0.0'f32,0.0'f32,0.0'f32].TVec3
  var aspect = 1 / aspect
  result.bl[0] = -1 * tan(fov/2)
  result.bl[1] = -1 * tan(fov/2) * aspect
  result.tr[0] = tan(fov/2)
  result.tr[1] = tan(fov/2) * aspect

proc getPixelPos(res: tuple[x,y: int], bounds: tuple[min,max: TVec3], t: TVec3, tmax: int): TVec3 =
  var dist = array[float32, 0..2]
  var step = array[float32, 0..2]
  for (idx, elm) in dist.pairs:
    dist[idx] = bounds.max[idx] - bounds.min[idx]
    step[idx] = dist[idx]/tmax
    result[idx] = bounds.min[idx] + step * t
  
when isMainModule:
  var(bottom, top) = getWindowBounds(45, (4.0/3.0))
  echo "Window is: " & $bottom & " and " & $top
  var TestSphere = TSphere(center: [0.0'f32,0.0'f32,-5.0'f32], radius: 5.0'f)
  var testLight = TLight(pos: [0.0'f32,0.0'f32,-2.0'f32], diffuse:[1.0'f32,1.0'f32,1.0'f32])
  var testWin = array[array[TVec3[0..479], 0..639]]
  var eyePos = [0.0'f32, 0.0'f32, 1.0'f32]
  var res = (640, 480)
  var bounds = getWindowBounds(45.0, (4.0/3.0))
  for (x, xelm) in testWin:
    for (y, elm) in xelm:
      testWin[x][y] = GetColor(getPixelPos(res, bounds, 