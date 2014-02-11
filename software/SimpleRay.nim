import linagl/vector
#import linagl/matrix
import ecs/Scene
import ecs/SceneNode
import strutils
import math
type TInterval = tuple[min: float, max: float]
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
  
proc findIntersectionPoint(ray: TVec3, eye: TVec3, sphere: TSphere): tuple[res: bool, val: TVec3] = 
  var d = findIntersection(ray, eye, sphere)
  if d < 0.0:
    result = (false, ray)
  else:
    result = (true, ray * d)
proc GetDiffuseColor(inter: TVec3, obj: TSphere, light: TLight): TVec3 =
  var toLight = inter - light.pos
  var norm = inter - obj.center
  var toLightN = toLight.normalized()
  norm = norm.normalized()
  var ndl: float = toLightN *. norm
  result = ndl.float32 * light.diffuse
proc GetColor(Ray: TVec3, eye: TVec3, sphere: TSphere, light: TLight): TVec3 =
  var obj = initSphere()
  var (hasIntersect, intersection) = findIntersectionPoint(ray, eye, sphere)
  var diffuseColor: TVec3 = GetDiffuseColor(intersection, sphere, light)
  if hasIntersect:
    result = diffuseColor
  else:
    result = [0.0'f32, 0.0'f32, 0.0'f32]
  
proc getWindowBounds(fov: float, aspect: float): tuple[bl, tr: TVec3] = 
  result.bl = [0.0'f32,0.0'f32,0.0'f32].TVec3
  result.tr = [0.0'f32,0.0'f32,0.0'f32].TVec3
  var aspect = 1 / aspect
  result.bl[0] = -1 * tan(fov/2)
  result.bl[1] = -1 * tan(fov/2) * aspect
  result.tr[0] = tan(fov/2)
  result.tr[1] = tan(fov/2) * aspect

proc scaleTo(fromr: TInterval, tor: TInterval, t: float): float =
  var steps = fromr.max - fromr.min
  var stepSize = (tor.max - tor.min) / steps
  var totalDist = (tor.max - tor.min)
  var pos = (t - fromr.min) / steps
  result = tor.min + (totalDist * pos)
when isMainModule:
  var(bottom, top) = getWindowBounds(45, (1.0))
  #echo "Window is: " & $bottom & " and " & $top
  var TestSphere = TSphere(center: [0.0'f32,0.0'f32,-20.0'f32], radius: 5.0)
  var testLight = TLight(pos: [10.0'f32,0.0'f32,-20.0'f32], diffuse:[1.0'f32,1.0'f32,1.0'f32])
  var testWin: array[0..19, array[0..19, TVec3]]
  var eyePos = [0.0'f32, 0.0'f32, 1.0'f32]
  var res = (x: 20.0, y: 20.0)
  var bounds = getWindowBounds(45.0, (1.0))
  for x, xelm in testWin:
    for y, elm in xelm:
      var rayx = scaleTo((0.0, res.x), (bounds.bl[0].float,bounds.tr[0].float), x.float)
      var rayy = scaleTo((0.0, res.y), (bounds.bl[1].float,bounds.tr[1].float), y.float)
      #echo($(rayx, rayy))
      var ray = [rayx.float32, rayy.float32, -1.0'f32]
      testWin[x][y] = GetColor(ray, eyePos, testSphere, testLight)
      var intersection = findIntersectionPoint(ray, eyePos, testSphere)
  for x in testWin:
    for y in x:
      write(stdout, formatFloat(y[2] * -1, ffDecimal, 3) & " ")
    echo ""
  #echo findIntersectionPoint([0.0'f32, 0.0'f32, -1.0'f32], eyePos, testSphere)
  
