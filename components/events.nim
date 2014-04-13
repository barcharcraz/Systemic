import ecs

type onMouseDown* = proc(x,y: float)
type onMouseUp* = proc(x,y: float)
MakeEntityComponent(onMouseUp)
MakeEntityComponent(onMouseDown)
