import macros
type MtxOptions = enum
  moColMaj,
  moRowMaj
type ColMajor = object
type RowMajor = object
type Options = ColMajor | RowMajor
type TMatrix[T; N, M: static[int]; O: static[set[MtxOptions]] = array[N*M, T]
type 
type
  TMat4f = TMatrix[float32, 4, 4, ColMajor]

proc mul(a: TMatrix; b: TMatrix): TMatrix =
  when a.M != b.N:
    error("Invalid matrix sizes for matrix multiplicatio")


