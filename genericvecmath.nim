import macros
type ColMajor = object
type RowMajor = object
type Options = ColMajor | RowMajor
type TMatrix*[N: static[int]; M: static[int]; T; O: Options] = object
  data: array[0..M*N-1, T]
type SquareMatrix = generic x
  x is TMatrix
  x.N == x.M
type 
  Vector[N: static[int]] = TMatrix[N, 1, float32, ColMajor]
type
  TVecf*[N: static[int]] = TMatrix[N, 1, float32, ColMajor]
  TMat4f* = TMatrix[4, 4, float32, ColMajor]
  TMat3f* = TMatrix[3, 3, float32, ColMajor]
  TVec4f* = TMatrix[4, 1, float32, ColMajor]
  TVec3f* = TMatrix[3, 1, float32, ColMajor]
  TVec2f* = TMatrix[2, 1, float32, ColMajor]
  TQuatf* = array[4, float32] #poor man's quaternion
type
  TAlignedBox3f* = object
    min: array[3, float32]
    max: array[3, float32]
discard """
proc i*(q: TQuatf): float32 = q[1]
proc j*(q: TQuatf): float32 = q[2]
proc k*(q: TQuatf): float32 = q[3]
proc w*(q: TQuatf): float32 = q[0]
proc at*(self: TMat4f; i,j: int): float32 =
  var idx = (4 * j) + i
  result = self[idx]
proc at*(self: TMat3f; i,j: int): float32 =
  var idx = (3 * j) + i
  result = self[idx]
proc mat*(self: var TMat4f; i,j: int): var float32 =
  var idx = (4 * j) + i
  result = self[idx]
proc identity4f(): TMat4f = 
  for i in 0..3:
    result.mat(i,i) = 1.0'f32
proc toRotMatrix*(q: TQuatf): TMat3f =
  result[0] = 1 - 2 * (q.j*q.j)
  result[1] = 2*(q.i*q.j + q.k*q.w)
  result[2] = 2*(q.i*q.k - q.j*q.w)
  result[3] = 2*(q.i*q.j - q.k*q.w)
  result[4] = 1 - 2*(q.i*q.i + q.k*q.k)
  result[5] = 2*(q.j*q.k - q.i*q.w)
  result[6] = 2*(q.j*q.w + q.i*q.k)
  result[7] = 2*(q.j*q.k - q.i*q.w)
  result[8] = 1 - 2*(q.j*q.j + q.i*q.i)
proc toTranslationMatrix*(v: TVec3f): TMat4f =
  result = identity4f()
  result.mat(0,3) = v[0]
  result.mat(1,3) = v[1]
  result.mat(2,3) = v[2]
proc toAffine*(m: TMat3f): TMat4f =
  for i in 0..2:
    for j in 0..2:
      result.mat(i,j) = m.at(i,j)
  result.mat(3,3) = 1
proc row*(a: TMat4f; r: int): TVec4f =
  result[0] = a.at(r, 0)
  result[1] = a.at(r, 1)
  result[2] = a.at(r, 2)
  result[3] = a.at(r, 3)
proc col*(a: TMat4f; c: int): TVec4f =
  result[0] = a.at(0, c)
  result[1] = a.at(1, c)
  result[2] = a.at(2, c)
  result[3] = a.at(3, c)
proc dot*[T: array](a: T; b: T): float32 =
  for i in 0..high(a):
    result = result + (a[i] * b[i])
proc mul*(a: TMat4f; b: TMat4f): TMat4f =
  for i in 0..3:
    for j in 0..3:
      result.mat(i,j) = dot(a.row(i), b.col(j))
"""
discard """
type RowMajorMatrix = generic x
  x is TMatrix
  x.O is RowMajor
type ColMajorMatrix = generic x
  x is TMatrix
  x.O is ColMajor
  
## gets the element at the ith row and the jth column
## of a matrix
"""

proc `[]=`(self: var TMatrix; i,j: int; val: TMatrix.T) =
  when TMatrix.O is RowMajor:
    var idx = (TMatrix.M * (i-1)) + (j-1)
    self.data[idx] = val
  when TMatrix.O is ColMajor:
    var idx = (TMatrix.N * (j-1)) + (i-1)
    self.data[idx] = val

proc `[]`(self: TMatrix; i,j: int): TMatrix.T =
  when TMatrix.O is RowMajor:
    var idx = (TMatrix.M * (i-1)) + (j-1)
    result = self.data[idx]
  when TMatrix.O is ColMajor:
    var idx = (TMatrix.N * (j-1)) + (i-1)
    result = self.data[idx]
proc `[]`(self: Vector; i: int): Vector.T =
  result = self[i, 1]
proc `[]=`(self: Vector; i: int; val: Vector.T) =
  self[i, 1] = val
proc rows(mtx: TMatrix): int = TMatrix.N
proc cols(mtx: TMatrix): int = TMatrix.M
proc identity[T: SquareMatrix](): T =
  for i in 1..result.rows():
    result[i,i] = 1
proc dot*(a, b: Vector): Vector.T =
  #assert(a.data.len == b.data.len)
  for i in 1..a.data.len:
    result += a[i] * b[i]
proc row*(a: TMatrix; i: int): auto =
  result = TMatrix[TMatrix.M, 1, TMatrix.T, TMatrix.O]()
  for idx in 1..TMatrix.M:
    result[idx] = a[i,idx]
discard """
proc mult(a: TMatrix; b: TMatrix): TMatrix =
  when a.N != b.M:
    {.fatal: "MIXED MATRICES OF DIFFEReNT SIZES".}
  for i in 1..a.N:
    for j in 1..b.M:
      result[i,j] = 
"""
discard """
const XSwiz = {'x', 'r', 'u' }
const YSwiz = {'y', 'g', 'v' }
const ZSwiz = {'z', 'b', 'w' }
const WSwiz = {'w', 'a'}
proc `.`(self: Vector; field: static[string]): TVec[field.len] =
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
  var realMtx: TMatrix[4, 4, float32, ColMajor]
  realMtx = identity[TMatrix[4,4,float32,ColMajor]]()
  echo repr(realMtx[1,1])
  test "TDotProduct":
    var a = TVec3f(data: [1.0'f32, 2.0'f32, 0.0'f32])
    var b = TVec3f(data: [0.0'f32, 5.0'f32, 1.0'f32])
    var c = dot(a,b)
    check(c == 10.0'f32)
  test "TRow":
    var a: TMat4f
    var r = a.row(1)
    check(r.data == [1'f32, 0'f32, 0'f32, 0'f32])


