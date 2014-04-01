import macros
import typetraits
import math
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
    min: array[3, float32]
    max: array[3, float32]
proc vec2f*(x,y: float32): TVec2f =
  result.data = [x,y]
proc vec3f*(x,y,z: float32): TVec3f =
  result.data = [x,y,z]
proc vec4f*(x,y,z,w: float32): TVec4f =
  result.data = [x,y,z,w]
proc vec4*[T](x,y,z,w: T): TVec4[T] =
  result.data = [x,y,z,w]
proc vec4*[T](v: TVec3[T], w: T): TVec4[T] =
  result.data = [v[1], v[2], v[3], w]

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
proc rows*(mtx: TMatrix): int = TMatrix.N
proc cols*(mtx: TMatrix): int = TMatrix.M
proc identity*[T](): T =
  for i in 1..rows(result):
    result[i,i] = 1.float32
proc dot*(a, b: TVec): TVec.T =
  #FIXME: perhaps this should return a float
  #assert(a.data.len == b.data.len)
  for i in 1..a.data.len:
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
proc adj*(a: TMat4f): TMat4f =
  for i in 1..4:
    for j in 1..4:
      var sgn = pow((-1).float, (i+j).float)
      result[i,j] = sgn * det(a.sub(j,i))
proc inverse*(a: TMat4f): TMat4f =
  result = adj(a)/det(a)
proc initMat3f*(arrs: array[0..8, float32]): TMat3f = 
  result.data = arrs
  result = transpose(result)
proc initMat2f*(arrs: array[0..3, float32]): TMat2f =
  result.data = arrs
  result = transpose(result)
proc mul*(a: TMat4f; b: TMat4f): TMat4f =
  for i in 1..4:
    for j in 1..4:
      result[i,j] = dot(row(a,i), col(b,j))
proc mulv*(a: TMat3f, b: TVec3f): TVec3f =
  for i in 1..3:
    result[i] = dot(a.row(i), b)
discard """
proc mul*(a: TMat3f; b: TMat3f): TMat3f =
  for i in 1..3:
    for j in 1..3:
      result[i,j] = dot(row(a,i), col(b,j))
"""
proc `==`*(a: TMatrix; b: TMatrix): bool =
  result = a.data == b.data
proc identity4f(): TMat4f =
  for i in 1..4:
    result[i,i] = 1'f32
#vector only code
proc x*(a: TVec): TVec.T = a[1]
proc y*(a: TVec): TVec.T = a[2]
proc z*(a: TVec): TVec.T = a[3]
proc norm*(a: TVec): float =
  sqrt(dot(a,a))
proc `+`*(a, b: TVec): TVec =
  for i in 1..TVec.N:
    result[i] = a[i] + b[i]
proc `+=`*(a: var TVec, b: TVec) =
  a = a+b
proc `-`*(a, b: TVec): TVec =
  for i in 1..TVec.N:
    result[i] = a[i] - b[i]
proc `*`*(a: TVec, b: float): TVec =
  for i in 1..TVec.N:
    result[i] = a[i] * b
proc dist*(a,b: TVec): float =
  result = length(a - b)
proc `$`*(a: TVec3f): string {.noSideEffect.} =
  result  =  "x: " & $a[1]
  result &= " y: " & $a[2]
  result &= " z: " & $a[3]
#transform related code
proc toAffine*(a: TMat3f): TMat4f =
  for i in 1..TMat3f.N:
    for j in 1..TMat3f.M:
      result[i,j] = a[i,j]
  result[4,4] = 1'f32
proc toTranslationMatrix*(v: TVec3f): TMat4f =
  result = identity4f()
  result[1,4] = v[1]
  result[2,4] = v[2]
  result[3,4] = v[3]
proc unProject*(win: TVec3; mtx: TMat4f, viewport: TVec4f): TVec3f =
  var inversevp = inverse(mtx)
  var tmp = vec4(win, 1'f32)
  tmp[1] = (tmp[1] - (viewport[1] / viewport[3]))
  tmp[2] = (tmp[2] - (viewport[2] / viewport[4]))
  tmp = (tmp * 2'f32) - 1'f32

  var obj = mul(inversevp, tmp)
  obj = obj / obj[4]
  result = vec3f(obj[1], obj[2], obj[3])
proc unProject*(win: TVec3; view, proj: TMat4f; viewport: TVec4f): TVec3f =
  unProject(win, mul(proj, view), viewport)
#quaternion related code
proc `[]`*(self: TQuatf; i: int): float32 = array[1..4, float32](self)[i]
proc `[]=`*(self: var TQuatf; i: int; val: float32) = array[1..4,float32](self)[i] = val
proc i*(q: TQuatf): float32 = q[2]
proc j*(q: TQuatf): float32 = q[3]
proc k*(q: TQuatf): float32 = q[4]
proc w*(q: TQuatf): float32 = q[1]
proc x*(q: TQuatf): float32 = q[2]
proc y*(q: TQuatf): float32 = q[3]
proc z*(q: TQuatf): float32 = q[4]
proc toVector(q: TQuatf): TVec4f =
  result.data = array[0..3, float32](q)
proc norm*(q: TQuatf): float = norm(toVector(q))
proc mul*(p: TQuatf; q: TQuatf): TQuatf =
  result[1] = p.w * q.w - p.x * q.x - p.y * q.y - p.z * q.z;
  result[2] = p.w * q.x + p.x * q.w + p.y * q.z - p.z * q.y;
  result[3] = p.w * q.y + p.y * q.w + p.z * q.x - p.x * q.z;
  result[4] = p.w * q.z + p.z * q.w + p.x * q.y - p.y * q.x;
proc toRotMatrix*(q: TQuatf): TMat3f =
  #this code is ported from Eigen
  #pretty much directly
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
proc quatFromAngleAxis*(angle: float; axis: TVec3f): TQuatf =
  var vecScale = sin(0.5 * angle)
  result[2] = axis[1] * vecScale
  result[3] = axis[2] * vecScale
  result[4] = axis[3] * vecScale
  result[1] = cos(0.5 * angle)

proc identityQuatf*(): TQuatf =
  result[1] = 1.0'f32
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


  test "TDotProduct":
    var av: TVec3f
    av.data = [1.0'f32, 2.0'f32, 0.0'f32]
    var bv: TVec3f
    bv.data = [0.0'f32, 5.0'f32, 1.0'f32]
    var cv = dot(av,bv)
    check(cv == 10.0'f32)
  
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
  discard """ 
  test "TSwizzle":
    var ta: TVec3f = TVec3f(data: [1.0'f32, 2.0'f32, 3.0'f32])
    check(ta.xxx == TVec3f(data: [1.0'f32, 1.0'f32, 1.0'f32] ))
  """
  #check(prod[1,1] == 8.0'f32)
  #check(prod[1,2] == 5.0'f32)
  #check(prod[2,1] == 20.0'f32)
  #check(prod[2,2] == 13.0'f32)


