import vecmath

type TAxisAlignedBB = object
  RestAABB: TAlignedBox3f
  CurAABB: TAlignedBox3f

proc initAABB*(initial: TAlignedBox3f): TAxisAlignedBB =
  result = TAxisAlignedBB(RestAABB: initial, CurAABB: initial)
  
