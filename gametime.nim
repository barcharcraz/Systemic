## implements high resolution timers
## for tracking game related things,
## at the moment this uses glfw's time support
import glfw/wrapper

var lastFrameTime: float
var lastCurrentTime: float

proc UpdateGameTime*() =
  var newTime = getTime()
  lastFrameTime = newTime - lastCurrentTime
  lastCurrentTime = newTime

proc GetFrameTime*(): float = lastFrameTime
