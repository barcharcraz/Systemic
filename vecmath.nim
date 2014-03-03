import macros
type ColMajor = object
type RowMajor = object
type Options = ColMajor | RowMajor
type TMatrix*[T; N: static[int]; M: static[int]; O: Options] = object
  data: array[N*M, T]
type
  TMat4f* = array[4*4, float32]
  TVec4f* = array[4, float32]
  TVec3f* = array[4, float32]
type
  TAlignedBox3f* = tuple[min: TVec3f, max: TVec3f]
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
when isMainModule:
  var testMtx: TMat4f = TMat4f(data:
      [1'f32, 2'f32, 3'f32, 4'f32,
      5'f32, 6'f32, 7'f32, 8'f32,
      9'f32, 10'f32, 11'f32, 12'f32,
      13'f32, 14'f32, 15'f32, 16'f32])
  echo TMat4f.N
  
