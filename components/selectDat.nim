import vecmath
import ecs
type TSelected* = object
  oldDiffuse*: TVec4f

MakeEntityComponent(TSelected)
