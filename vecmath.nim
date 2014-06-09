import math
import strutils
type ColMajor = object
type RowMajor = object
type Options = generic x
  x is ColMajor or
    x is RowMajor
type TMatrix*[N: static[int]; M: static[int]; T; O: Options] = object
  data*: array[0..M*N-1, T]
type 
  SquareMatrix[N: static[int]; T] = TMatrix[N,N,T,ColMajor]
type SquareMatGT[T: static[int]] = generic x
  x is SquareMatrix
  x.N > T
type
  TVec*[N: static[int]; T] = TMatrix[N, 1, T, ColMajor]
  TVec3*[T] = TVec[3, T]
  TVec4*[T] = TVec[4, T]
  TVecf*[N: static[int]] = TMatrix[N, 1, float32, ColMajor]
  TMat2*[T] = TMatrix[2,2,T, ColMajor]
  TMat3*[T] = TMatrix[3,3,T, ColMajor]
  TMat4*[T] = TMatrix[4,4,T, ColMajor]
  TMat4f* = TMatrix[4, 4, float32, ColMajor]
  TMat3f* = TMatrix[3, 3, float32, ColMajor]
  TMat2f* = TMatrix[2, 2, float32, ColMajor]
  TVec6f* = TMatrix[6, 1, float32, ColMajor]
  TVec5f* = TMatrix[5, 1, float32, ColMajor]
  TVec4f* = TMatrix[4, 1, float32, ColMajor]
  TVec3f* = TMatrix[3, 1, float32, ColMajor]
  TVec2f* = TMatrix[2, 1, float32, ColMajor]
  TQuatf* = distinct array[1..4, float32] #poor man's quaternion
type
  TAlignedBox3f* = object
    min*: TVec3f
    max*: TVec3f
type TAxis* = enum
  axisYZ = 1,
  axisXZ = 2,
  axisXY = 3
proc `[]=`*(self: var TMatrix; i,j: int; val: TMatrix.T) =
  when TMatrix.O is RowMajor:
    var idx = (TMatrix.M * (i-1)) + (j-1)
    self.data[idx] = val
  when TMatrix.O is ColMajor:
    var idx = (TMatrix.N * (j-1)) + (i-1)
    self.data[idx] = val

proc `[]`*(self: TMatrix; i,j: int): TMatrix.T =
  when TMatrix.O is RowMajor:
    var idx = (TMatrix.M * (i-1)) + (j-1)
    result = self.data[idx]
  when TMatrix.O is ColMajor:
    var idx = (TMatrix.N * (j-1)) + (i-1)
    result = self.data[idx]
proc `[]`*(self: TVec; i: int): TVec.T =
  result = self[i, 1]
proc `[]=`*(self: var TVec; i: int; val: TVec.T) =
  self[i, 1] = val

proc vec2f*(x,y: float32): TVec2f =
  result.data = [x,y]
proc vec3f*(x,y,z: float32): TVec3f =
  result.data = [x,y,z]
proc vec4f*(x,y,z,w: float32): TVec4f =
  result.data = [x,y,z,w]
proc vec4f*(v: TVec3f, w: float32): TVec4f =
  result.data = [v[1], v[2], v[3], w]
proc vec4*[T](x,y,z,w: T): TVec4[T] =
  result.data = [x,y,z,w]
proc vec4*[T](v: TVec3[T], w: T): TVec4[T] =
  result.data = [v[1], v[2], v[3], w]


proc rows*(mtx: TMatrix): int = TMatrix.N
proc cols*(mtx: TMatrix): int = TMatrix.M
proc identity*[T](): T =
  for i in 1..rows(result):
    result[i,i] = 1.float32
proc dot*(a, b: TVec): TVec.T =
  #FIXME: perhaps this should return a float
  #assert(a.data.len == b.data.len)
  for i in 1..TVec.N:
    result += a[i] * b[i]
proc length*(a: TVec): float =
  result = sqrt(dot(a,a).float)
proc row*(a: TMatrix; i: int): auto =
  result = TVec[TMatrix.M, TMatrix.T]()
  for idx in 1..TMatrix.M:
    result[idx] = a[i,idx]
proc col*(a: TMatrix; j: int): auto =
  result = TVec[TMatrix.N, TMatrix.T]()
  for idx in 1..TMatrix.N:
    result[idx] = a[idx, j]
proc `/`*(a: TMatrix, c: float): TMatrix =
  for i in 1..TMatrix.N:
    for j in 1..TMatrix.M:
      result[i,j] = a[i,j] / c
proc sub*(self: TMatrix; r,c: int): auto =
  ## returns a submatrix of `self`, that is
  ## we delete the ith row and jth column
  ## and return the resulting matrix
  result = TMatrix[TMatrix.N - 1, TMatrix.M - 1, TMatrix.T, TMatrix.O]()
  for i in 1..TMatrix.N-1:
    for j in 1..TMatrix.M-1:
      #we just handle the four cases here
      #we could be in any one of the four quadrents
      #defined by the row and col we are removing
      if i >= r and j >= c: result[i,j] = self[i+1,j+1]
      elif i >= r: result[i,j] = self[i+1, j]
      elif j >= c: result[i,j] = self[i, j+1]
      else: result[i,j] = self[i,j]
proc transpose*(a: TMatrix): TMatrix =
  for i in 1..TMatrix.N:
    for j in 1..TMatrix.M:
      result[i,j] = a[j,i]

proc det*(a: SquareMatrix): float =
  static: echo SquareMatrix.N
  when SquareMatrix.N == 2:
    result = (a[1,1] * a[2,2]) - (a[1,2] * a[2,1])
  else:
    for i in 1..SquareMatrix.N:
      var sgn = pow((-1).float,(i + 1).float)
      result += sgn * a[i,1] * det(a.sub(i,1))

discard """
proc det2*(a: TMat2f): float =
  result = (a[1,1] * a[2,2]) - (a[1,2] * a[2,1])
proc det*(a: TMat3f): float =
  for i in 1..3:
    var sgn = pow((-1).float, (i + 1).float)
    result += sgn * a[i,1] * det2(a.sub(i,1))
"""
proc adj*(a: TMat4f): TMat4f =
  for i in 1..4:
    for j in 1..4:
      var sgn = pow((-1).float, (i+j).float)
      result[i,j] = sgn * det(a.sub(j,i))
proc inverse*(a: TMat4f): TMat4f =
  result = adj(a)/det(a)
proc trace*(a: SquareMatrix): float =
  for i in 1..SquareMatrix.N:
    result += a[i,i]
proc initMat3f*(arrs: array[0..8, float32]): TMat3f = 
  result.data = arrs
  result = transpose(result)
proc initMat2f*(arrs: array[0..3, float32]): TMat2f =
  result.data = arrs
  result = transpose(result)
proc `$`(a: TMat3f): string =
  result = formatFloat(a[1,1]) & " " & formatFloat(a[1,2]) & formatFloat(a[1,3]) & "\n" &
           formatFloat(a[2,1]) & " " & formatFloat(a[2,2]) & formatFloat(a[2,3]) & "\n" &
           formatFloat(a[3,1]) & " " & formatFloat(a[3,2]) & formatFloat(a[3,3])
proc mul*(a: TMat4f; b: TMat4f): TMat4f =
  for i in 1..4:
    for j in 1..4:
      result[i,j] = dot(row(a,i), col(b,j))
proc mulv*(a: TMat3f, b: TVec3f): TVec3f =
  for i in 1..3:
    result[i] = dot(a.row(i), b)
proc mul4v*(a: TMat4f, v: TVec4f): TVec4f =
  for i in 1..4:
    result[i] = dot(a.row(i), v)
discard """
proc mul*(a: TMat3f; b: TMat3f): TMat3f =
  for i in 1..3:
    for j in 1..3:
      result[i,j] = dot(row(a,i), col(b,j))
"""
proc `==`*(a: TMatrix; b: TMatrix): bool =
  result = a.data == b.data
proc identity4f*(): TMat4f =
  for i in 1..4:
    result[i,i] = 1'f32
proc identity3f*(): TMat3f =
  for i in 1..3:
    result[i,i] = 1'f32
#vector only code
proc x*(a: TVec): TVec.T = a[1]
proc y*(a: TVec): TVec.T = a[2]
proc z*(a: TVec): TVec.T = a[3]
proc `x=`*(a: var TVec, val: TVec.T) = a[1] = val
proc `y=`*(a: var TVec, val: TVec.T) = a[2] = val
proc `z=`*(a: var TVec, val: TVec.T) = a[3] = val
proc xyz*(a: TVec4f): TVec3f = vec3f(a.x, a.y, a.z)
proc norm*(a: TVec): float =
  sqrt(dot(a,a))
proc normalize*(a: TVec): TVec =
  result = a / norm(a)
proc `+`*(a, b: TVec): TVec =
  for i in 1..TVec.N:
    result[i] = a[i] + b[i]
proc `+=`*(a: var TVec, b: TVec) =
  a = a+b
proc `-`*(a, b: TVec): TVec =
  for i in 1..TVec.N:
    result[i] = a[i] - b[i]
proc `-`*(a: TVec, c: float): TVec =
  for i in 1..TVec.N:
    result[i] = a[i] - c
proc `*`*(a: TVec, b: float): TVec =
  for i in 1..TVec.N:
    result[i] = a[i] * b
proc `*`*(b: float, a: TVec): TVec = a * b
proc `<`*(a: TVec, b: TVec): bool =
  result = true
  for i in 1..TVec.N:
    if a[i] >= b[i]:
      return false
proc dist*(a,b: TVec): float =
  result = norm(a - b)
proc formatVec3f*(a: TVec3f): string {.noSideEffect.} =
  result  =  "x: " & formatFloat(a[1])
  result &= " y: " & formatFloat(a[2])
  result &= " z: " & formatFloat(a[3])
proc formatVec4f*(a: TVec4f): string {.noSideEffect.} =
  result  =  "x: " & formatFloat(a[1])
  result &= " y: " & formatFloat(a[2])
  result &= " z: " & formatFloat(a[3])
  result &= " w: " & formatFloat(a[4])
proc cross*(u,v: TVec3f): TVec3f =
  result.x = (u.y * v.z) - (u.z * v.y)
  result.y = (u.z * v.x) - (u.x * v.z)
  result.z = (u.x * v.y) - (u.y * v.x)

#AABB related code
proc extend*(aabb: var TAlignedBox3f, target: TVec3f) =
  if target < aabb.min:
    aabb.min = target
  if target > aabb.max:
    aabb.max = target
proc extend*(aabb: var TAlignedBox3f, target: TAlignedBox3f) =
  if target.min < aabb.min:
    aabb.min = target.min
  if target.max > aabb.max:
    aabb.max = target.max
proc `in`(target: TAlignedBox3f, aabb: TAlignedBox3f): bool =
  if (target.min > aabb.min) and (target.max < aabb.max):
    return true
  return false
proc split*(aabb: TAlignedBox3f, axis: TAxis): tuple[a,b: TAlignedBox3f] =
  result.a = aabb
  result.b = aabb
  var axisIdx = axis.int
  var diff = aabb.max - aabb.min
  result.a.min[axisIdx] = result.a.min[axisIdx] + diff.z
  result.b.max[axisIdx] = result.b.max[axisIdx] - diff.z
proc split*(aabb: TAlignedBox3f, axis: TAxis; a,b: var TAlignedBox3f) =
  var (tmpa, tmpb) = split(aabb, axis)
  a = tmpa
  b = tmpb
proc split*(aabb: TAlignedBox3f): array[1..8, TAlignedBox3f] =
  split(aabb, axisYZ, result[1], result[3])
  split(result[1], axisXZ, result[1], result[2])
  split(result[3], axisXZ, result[3], result[4])
  split(result[1], axisXY, result[1], result[5])
  split(result[2], axisXY, result[2], result[6])
  split(result[3], axisXY, result[3], result[7])
  split(result[4], axisXY, result[4], result[8])
proc centroid*(aabb: TAlignedBox3f): TVec3f =
  result = (aabb.min + aabb.max) / 2
#transform related code
proc toAffine*(a: TMat3f): TMat4f =
  for i in 1..TMat3f.N:
    for j in 1..TMat3f.M:
      result[i,j] = a[i,j]
  result[4,4] = 1'f32
proc fromAffine*(a: TMat4f): TMat3f =
  for i in 1..3:
    for j in 1..3:
      result[i,j] = a[i,j]
proc toTranslationMatrix*(v: TVec3f): TMat4f =
  result = identity4f()
  result[1,4] = v[1]
  result[2,4] = v[2]
  result[3,4] = v[3]
proc fromTranslationMtx*(m: TMat4f): TVec3f =
  result[1] = m[1,4]
  result[2] = m[2,4]
  result[3] = m[3,4]
proc unProject*(win: TVec3f; mtx: TMat4f, viewport: TVec4f): TVec3f =
  var inversevp = inverse(mtx)
  var tmp = vec4f(win, 1'f32)
  tmp[1] = (tmp[1] - viewport[1]) / viewport[3]
  tmp[2] = (tmp[2] - viewport[2]) / viewport[4]
  tmp = (tmp * 2'f32) - 1'f32
  var obj = mul4v(inversevp, tmp)
  obj = obj / obj[4]
  result = vec3f(obj[1], obj[2], obj[3])
proc unProject*(win: TVec3f; view, proj: TMat4f; viewport: TVec4f): TVec3f =
  unProject(win, mul(proj, view), viewport)
#projection related code
proc CreateOrthoMatrix*(min, max: TVec3f): TMat4f =
  var sx = 2 / (max.x - min.x)
  var sy = 2 / (max.y - min.y)
  var sz = 2 / (max.z - min.z)
  var tx = -( max.x + min.x )/( max.x - min.x )
  var ty = -( max.y + min.y )/( max.y - min.y )
  var tz = -( max.z + min.z )/( max.z - min.z )
  result.data = [sx, 0,   0,    0,
                 0,  sy,  0,    0,
                 0,  0,   sz,   0,
                 tx,  ty, tz,   1]
#quaternion related code
proc `[]`*(self: TQuatf; i: int): float32 = array[1..4, float32](self)[i]
proc `[]=`*(self: var TQuatf; i: int; val: float32) = array[1..4,float32](self)[i] = val
proc `==`*(a,b: TQuatf): bool {.borrow.}
proc i*(q: TQuatf): float32 = q[2]
proc j*(q: TQuatf): float32 = q[3]
proc k*(q: TQuatf): float32 = q[4]
proc w*(q: TQuatf): float32 = q[1]
proc `i=`*(q: var TQuatf, val: float32) = q[2] = val
proc `j=`*(q: var TQuatf, val: float32) = q[3] = val
proc `k=`*(q: var TQuatf, val: float32) = q[4] = val
proc `w=`*(q: var TQuatf, val: float32) = q[1] = val
proc x*(q: TQuatf): float32 = q[2]
proc y*(q: TQuatf): float32 = q[3]
proc z*(q: TQuatf): float32 = q[4]
proc mul*(p: TQuatf, q: TQuatf): TQuatf
proc `/`*(q: TQuatf, s: float): TQuatf =
  result.i = q.i / s
  result.j = q.j / s
  result.k = q.k / s
  result.w = q.w / s
proc `/`*(q: TQuatf, s: float32): TQuatf = q / s.float
proc quatf*(w,i,j,k: float32): TQuatf = [w,i,j,k].TQuatf
proc toVector(q: TQuatf): TVec4f =
  result.data = array[0..3, float32](q)
proc norm*(q: TQuatf): float = norm(toVector(q))
proc normalize*(q: TQuatf): TQuatf = q / norm(q)
proc conj*(q: TQuatf): TQuatf =
  result.i = -q.i
  result.j = -q.j
  result.k = -q.k
  result.w = q.w
proc inverse*(q: TQuatf): TQuatf =
  result = conj(q)
  result = result / mul(q, conj(q)).w
proc mul*(p: TQuatf; q: TQuatf): TQuatf =
  result[1] = p.w * q.w - p.x * q.x - p.y * q.y - p.z * q.z;
  result[2] = p.w * q.x + p.x * q.w + p.y * q.z - p.z * q.y;
  result[3] = p.w * q.y + p.y * q.w + p.z * q.x - p.x * q.z;
  result[4] = p.w * q.z + p.z * q.w + p.x * q.y - p.y * q.x;
proc mulv*(q: TQuatf; v: TVec3f): TVec3f =
  var qv = quatf(0, v.x, v.y, v.z)
  var prod = mul(q, mul(qv, conj(q)))
  result = vec3f(prod.i, prod.j, prod.k)
proc toRotMatrix*(q: TQuatf): TMat3f =
  #this code is ported from Eigen
  #pretty much directly
  if not(norm(q) <= 1.1'f32 and norm(q) >= 0.9'f32):
    echo("bad quat: " & repr(q))
  assert(norm(q) <= 1.1'f32 and norm(q) >= 0.9'f32)
  var tx: float32 = float32(2)*q.x()
  var ty: float32 = float32(2)*q.y()
  var tz: float32 = float32(2)*q.z()
  var twx: float32 = tx*q.w()
  var twy: float32 = ty*q.w()
  var twz: float32 = tz*q.w()
  var txx: float32 = tx*q.x()
  var txy: float32 = ty*q.x()
  var txz: float32 = tz*q.x()
  var tyy: float32 = ty*q.y()
  var tyz: float32 = tz*q.y()
  var tzz: float32 = tz*q.z()
  result[1,1] = float32(1)-(tyy+tzz)
  result[1,2] = txy-twz
  result[1,3] = txz+twy
  result[2,1] = txy+twz
  result[2,2] = float32(1)-(txx+tzz)
  result[2,3] = tyz-twx
  result[3,1] = txz-twy
  result[3,2] = tyz+twx
  result[3,3] = float32(1)-(txx+tyy)
proc fromRotMatrix*(m: TMat3f): TQuatf =
  ## convert a rotation matrix into a quaternion
  ## this algorithm comes from the Eigen linear algebra
  ## library which in turn credits it to Ken Shoemake
  var t = trace(m)
  if t > 0:
    t = sqrt(t + 1.0)
    result.w = 0.5 * t
    t = 0.5/t
    result.i = (m[3,2] - m[2,3]) * t
    result.j = (m[1,3] - m[3,1]) * t
    result.k = (m[2,1] - m[1,2]) * t
  else:
    var i = 1
    if m[2,2] > m[1,1]:
      i = 2
    if m[3,3] > m[i,i]:
      i = 3
    var j = (i+1) mod 3
    var k = (j+1) mod 3
    inc(j)
    inc(k)
    t = sqrt(m[i,i] - m[j,j] - m[k,k] + 1.0)
    result[i] = 0.5 * t
    t = 0.5 / t
    result.w = (m[k,j] - m[j,k]) * t
    result[j] = (m[j,i] + m[i,j]) * t
    result[k] = (m[k,i] + m[i,k]) * t
proc toOrbitRotMatrix*(q: TQuatf, pos: TVec3f): TMat4f =
  result = toTranslationMatrix(-1 * pos)
  result = mul(result, toAffine(toRotMatrix(q)))
  result = mul(result, toTranslationMatrix(pos))
proc quatFromAngleAxis*(angle: float; axis: TVec3f): TQuatf =
  var vecScale = sin(0.5 * angle)
  result[2] = axis[1] * vecScale
  result[3] = axis[2] * vecScale
  result[4] = axis[3] * vecScale
  result[1] = cos(0.5 * angle)

proc identityQuatf*(): TQuatf =
  result[1] = 1.0'f32
  result[2] = 0.0'f32
  result[3] = 0.0'f32
  result[4] = 0.0'f32



discard """
const XSwiz = {'x', 'r', 'u' }
const YSwiz = {'y', 'g', 'v' }
const ZSwiz = {'z', 'b', 'w' }
const WSwiz = {'w', 'a'}
proc `.`*[N: static[int]; T](self: TVec[N, T]; field: static[string]): TVec[field.len, T] =
  for i in 1..field.len:
    if field[i-1] in XSwiz:
      result[i] = self[1]
    if field[i-1] in YSwiz:
      result[i] = self[2]
    if field[i-1] in ZSwiz:
      result[i] = self[3]
    if field[i-1] in WSwiz:
      result[i] = self[4]
"""
when isMainModule:

  import unittest

  test "TLessThan":
    var av = vec3f(0,0,0)
    var bv = vec3f(1,1,1)
    check(av < bv)
  test "TNotLessThan":
    var av = vec3f(1,1,1)
    var bv = vec3f(0,1,0)
    check(not (av > bv))
    check(not (av < bv))
  test "TExtend":
    var aabb: TAlignedBox3f
    var av = vec3f(5,5,5)
    aabb.extend(av)
    check(aabb.max == av)
  test "TDotProduct":
    var av: TVec3f
    av.data = [1.0'f32, 2.0'f32, 0.0'f32]
    var bv: TVec3f
    bv.data = [0.0'f32, 5.0'f32, 1.0'f32]
    var cv = dot(av,bv)
    check(cv == 10.0'f32)
  test "TCross1":
    var a = vec3f(1,0,0)
    var b = vec3f(0,1,0)
    var c = cross(a,b)
    check(c == vec3f(0,0,1))
  test "TRow":
    var ta: TMat4f
    ta[1,1] = 1.0'f32
    var tr = ta.row(1)
    check(tr.data == [1'f32, 0'f32, 0'f32, 0'f32])
  test "TColumn":
    var ta: TMat4f
    ta[1,1] = 1.0'f32
    var tc = ta.col(1)
    check(tc.data == [1.0'f32, 0.0'f32, 0.0'f32, 0.0'f32])
  test "TMul":
    var ta: TMat4f
    ta[1,2] = 2.0'f32
    var tb: TMat4f
    tb[2,1] = 2.0'f32
  #  discard mul(ta, tb)
  test "TestMat3f":
    var tm3: TMat3f
    var tm4 = toAffine(tm3)
    check(tm4[4,4] == 1.0'f32)
  test "Test Construct":
    #I actually had a bug where constructors just stopped working
    var vec4: TVec4f = vec4f(1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32)
    check(vec4.data == [1.0'f32, 1.0'f32, 1.0'f32, 1.0'f32])
  test "TSub":
    var a = initMat3f([1'f32,2'f32,3'f32,
                       4'f32,5'f32,6'f32,
                       7'f32,8'f32,9'f32])
    var c = initMat2f([1'f32, 3'f32,
                       7'f32, 9'f32])
    var b:TMat2f = a.sub(2,2)
    var e:bool = b == c
    check(e)
  test "TDet2x2":
    var a = initMat2f([1'f32,2'f32,3'f32,4'f32])
    var da = det(a)
    check(da == -2'f32)
  test "TDet3x3f":
    var a = initMat3f([1'f32, 2'f32, 3'f32, 
                       4'f32, 5'f32, 6'f32,
                       7'f32, 8'f32, 9'f32])
    var da = det(a)
    check(da == 0.0)
  test "TAdj3x3":
    var a = initMat3f([1'f32, 2'f32, 3'f32, 
                       4'f32, 5'f32, 6'f32,
                       7'f32, 8'f32, 9'f32])
    var aj = adj(a)
    var b = initMat3f([-3'f32, 6'f32, -3'f32,
                        6'f32, -12'f32, 6'f32,
                        -3'f32, 6'f32, -3'f32])
    var e = aj == b
    check(e)
  test "TMatToQuat1":
    var rot = quatFromAngleAxis(0.5, vec3f(1,0,0))
    var mtx = toRotMatrix(rot)
    var newRot = fromRotMatrix(mtx)
    check(newRot == rot)
  discard """ 
  test "TSwizzle":
    var ta: TVec3f = TVec3f(data: [1.0'f32, 2.0'f32, 3.0'f32])
    check(ta.xxx == TVec3f(data: [1.0'f32, 1.0'f32, 1.0'f32] ))
  """
  #check(prod[1,1] == 8.0'f32)
  #check(prod[1,2] == 5.0'f32)
  #check(prod[2,1] == 20.0'f32)
  #check(prod[2,2] == 13.0'f32)


