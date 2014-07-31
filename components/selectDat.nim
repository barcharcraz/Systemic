import vecmath
import ecs
type TSelected* = object
  oldDiffuse*: TVec4f

proc initSelected*(): TSelected = return result
MakeEntityComponent(TSelected)
