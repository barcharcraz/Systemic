from input import nil
import glfw/glfw
import glfw/wrapper
import tables
import logging
import hashes
var winDat = initTable[PWnd, ptr input.TInputMapping]()
proc hash(wnd: PWnd): THash = 
  #the handle member is not exported
  #and we need a unique identifier for
  #each window, we are just extracting
  #that handle pointer here, in the most
  #insane way possible
  hash(cast[ptr pointer](wnd)[])
proc `$`(wnd: PWnd): string =
  result = $cast[int](cast[ptr pointer](wnd)[])
proc getKey(k: glfw.TKey): input.TKey =
  case k
  of glfw.keyUnknown: return input.keyUnknown
  of glfw.keyA..glfw.KeyZ:
    var intVal = cast[int](k)
    const keyAVal = glfw.keyA.int
    const inputKeyAVal = input.keyA.int
    return cast[input.TKey]((intVal - keyAVal) + inputKeyAVal)
  else:
    return input.keyUnknown
proc keyCb(o: PWnd; key: glfw.TKey; scanCode: int; action: TKeyAction;
           modKeys: TModifierKeySet) =
  #this line is batshit, since PWnd.handle
  #is not exported and we need the user pointer
  #we exploit the fact that the first member
  #of PWnd is a GLFWwindow* and use this
  #to cast. OOP bitches
  if not winDat.hasKey(o):
    return
  var winData = winDat[o]
  if winData == nil:
    return
  var inputkey = getKey(key)
  if inputkey != input.keyUnknown:
    if action == kaDown: input.ActivateKey(winData[], inputKey)
    if action == kaUp: input.DeactivateKey(winData[], inputKey)
  else:
    info("Unknown key: " & $key)

var lastX: float64
var lastY: float64
proc handleMouse*(wnd: PWnd) =
  if not winDat.hasKey(wnd):
    return
  var winData = winDat[wnd]
  if winData == nil:
    return
  var pos = wnd.cursorPos()
  var size = wnd.size()

  var dx = pos.x - lastX
  var dy = pos.y - lastY
  lastX = pos.x
  lastY = pos.y
  input.SetAxis(winData[], "mouseX", dx / (size.w).float)
  input.SetAxis(winData[], "mouseY", dy / (size.h).float)
proc cursorEnterCb(wnd: PWnd; entered: bool) =
  var pos = wnd.cursorPos()
  if entered == true:
    echo("set last X/Y to: " & $pos.x & " " & $pos.y)
    lastX = pos.x
    lastY = pos.y
proc closeCb(wnd: PWnd) =
  winDat.del(wnd)

proc AttachInput*(wnd: PWnd; inp: var input.TInputMapping) =
  wnd.keyCb = keyCb
  wnd.wndCloseCb = closeCb
  #wnd.cursorEnterCb = cursorEnterCb
  if not winDat.hasKey(wnd):
    winDat.add(wnd, addr inp)
  else:
    winDat[wnd] = addr inp
  echo("attached to: " & $wnd)
  proc `$`(a: ptr input.TInputMapping): string = $cast[int](a)
  echo winDat
proc DetachInput*(wnd: PWnd; inp: var input.TInputMapping) =
  if not winDat.hasKey(wnd):
    info("window does not have any attached input maps")
    return
  if winDat.mget(wnd) == nil:
    info("window does not have any attached input maps")
    winDat.del(wnd)
    return
  if winDat[wnd] != addr inp:
    warn("currently attched input map is different from map attempted to remove")
  wnd.keyCb = nil
  wnd.wndCloseCb = nil
  #wnd.cursorEnterCb = nil
  winDat.del(wnd)

proc pollMouse*(self: PWnd): input.TMouse =
  var (x,y) = self.cursorPos
  result.x = x
  result.y = y
  # TODO: include all the mouse buttons
  #       here, not just L and R
  if self.mouseBtnDown(mbLeft):
    result.buttons.incl(input.mbLeft)
  if self.mouseBtnDown(mbRight):
    result.buttons.incl(input.mbRight)
