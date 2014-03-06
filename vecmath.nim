import macros
type ColMajor = object
type RowMajor = object
type Options = ColMajor | RowMajor
type TMatrix*[T; N: static[int]; M: static[int]; O: Options] = object
  data: array[N*M, T]
type
  TMat4f* = array[4*4, float32]
  TMat3f* = array[3*3, float32]
  TVec4f* = array[4, float32]
  TVec3f* = array[4, float32]
  TVec2f* = array[2, float32]
  TQuatf* = array[4, float32] #poor man's quaternion
type
  TAlignedBox3f* = tuple[min: TVec3f, max: TVec3f]
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
  for i in 0..3
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
proc toAffine(m: TMat3f): TMat4f =
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
discard """
proc at(self: TMatrix; i,j: int): auto =
  when self.O is RowMajor:
    var idx = (self.M * i) + j
    result = self.data[idx]
  when self.O is ColMajor:
    var idx = (self.N * j) + i
    result = self.data[idx]


proc `[]`(self: TMatrix; i,j:int): self.T =
  self.at(i,j)

proc mul[T; NA, MA, NB, MB: static[int]](a: TMatrix[T, NA, MA, RowMajor]; b: TMatrix[T, NB, MB, RowMajor]): TMatrix[T, NA, MB, RowMajor] =
  discard
"""

  
