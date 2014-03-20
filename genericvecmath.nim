import macros
import typetraits
type ColMajor = object
type RowMajor = object
type Options = generic x
  x is ColMajor or
    x is RowMajor
type TMatrix*[N: static[int]; M: static[int]; T; O: Options] = object
  data: array[0..M*N-1, T]
type 
  SquareMatrix[N: static[int]; T] = TMatrix[N,N,T,ColMajor]
type
  TVec*[N: static[int]; T] = TMatrix[N, 1, T, ColMajor]
  TVecf*[N: static[int]] = TMatrix[N, 1, float32, ColMajor]
  TMat4f* = TMatrix[4, 4, float32, ColMajor]
  TMat3f* = TMatrix[3, 3, float32, ColMajor]
  TMat2f* = TMatrix[2, 2, float32, ColMajor]
  TVec4f* = TMatrix[4, 1, float32, ColMajor]
  TVec3f* = TMatrix[3, 1, float32, ColMajor]
  TVec2f* = TMatrix[2, 1, float32, ColMajor]
  TQuatf* = array[4, float32] #poor man's quaternion
type
  TAlignedBox3f* = object
    min: array[3, float32]
    max: array[3, float32]

proc `[]=`(self: var TMatrix; i,j: int; val: TMatrix.T) =
  when TMatrix.O is RowMajor:
    var idx = (TMatrix.M * (i-1)) + (j-1)
    self.data[idx] = val
  when TMatrix.O is ColMajor:
    echo("i: " & $i & " j: " & $j)
    echo(name(type self))
    echo("Matrix.N: " & $TMatrix.N)
    var idx = (TMatrix.N * (j-1)) + (i-1)
    echo idx
    self.data[idx] = val

proc `[]`(self: TMatrix; i,j: int): TMatrix.T =
  when TMatrix.O is RowMajor:
    var idx = (TMatrix.M * (i-1)) + (j-1)
    result = self.data[idx]
  when TMatrix.O is ColMajor:
    var idx = (TMatrix.N * (j-1)) + (i-1)
    result = self.data[idx]
proc `[]`(self: TVec; i: int): TVec.T =
  result = self[i, 1]
proc `[]=`(self: var TVec; i: int; val: TVec.T) =
  self[i, 1] = val
proc rows(mtx: TMatrix): int = TMatrix.N
proc cols(mtx: TMatrix): int = TMatrix.M
proc identity[T](): T =
  for i in 1..rows(result):
    result[i,i] = 1.float32
proc dot*(a, b: TVec): TVec.T =
  #assert(a.data.len == b.data.len)
  for i in 1..a.data.len:
    result += a[i] * b[i]
proc row*(a: TMatrix; i: int): auto =
  result = TMatrix[TMatrix.M, 1, TMatrix.T, TMatrix.O]()
  for idx in 1..TMatrix.M:
    result[idx] = a[i,idx]
proc col*(a: TMatrix; j: int): auto =
  result = TMatrix[TMatrix.N, 1, TMatrix.T, TMatrix.O]()
  for idx in 1..TMatrix.N:
    result[idx] = a[idx, j]
proc mult(a: TMatrix; b: TMatrix): TMatrix =
  when a.N != b.M:
    {.fatal: "MIXED MATRICES OF DIFFEReNT SIZES".}
  for i in 1..a.N:
    for j in 1..b.M:
      result[i,j] = dot(row(a,i), col(b,j))
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
  realMtx = identity[SquareMatrix[4, float32]]()
  echo repr(realMtx[1,1])

  test "TDotProduct":
    var av = TVec3f(data: [1.0'f32, 2.0'f32, 0.0'f32])
    var bv = TVec3f(data: [0.0'f32, 5.0'f32, 1.0'f32])
    var cv = dot(av,bv)
    check(cv == 10.0'f32)
  
  test "TRow":
    var ta: TMat4f
    ta[1,1] = 1.0'f32
    var tr = ta.row(1)
    check(tr.data == [1'f32, 0'f32, 0'f32, 0'f32])
  echo("foo" & $TMat2f.N)
 
  var a: TMat2f
  echo("A rows: " & $(a.N))
  a[1,1] = 1.0'f32
  a[1,2] = 2.0'f32
  a[2,1] = 3.0'f32
  a[2,2] = 4.0'f32
  var b: TMat2f
  b[1,1] = 4.0'f32
  b[1,2] = 3.0'f32
  b[2,1] = 2.0'f32
  b[2,2] = 1.0'f32
  var prod = mult(a,b)
  #check(prod[1,1] == 8.0'f32)
  #check(prod[1,2] == 5.0'f32)
  #check(prod[2,1] == 20.0'f32)
  #check(prod[2,2] == 13.0'f32)


