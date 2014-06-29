from input import nil
import glfw/glfw
import glfw/wrapper
import tables
import logging
import hashes
var winDat = initTable[PWin, ptr input.TInputMapping]()
proc hash(wnd: PWin): THash = 
  #the handle member is not exported
  #and we need a unique identifier for
  #each window, we are just extracting
  #that handle pointer here, in the most
  #insane way possible
  hash(cast[ptr pointer](wnd)[])
proc `$`(wnd: PWin): string =
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
proc keyCb(o: PWin; key: glfw.TKey; scanCode: int; action: TKeyAction;
           modKeys: TModifierKeySet) =
  #this line is batshit, since PWin.handle
  #is not exported and we need the user pointer
  #we exploit the fact that the first member
  #of PWin is a GLFWwindow* and use this
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
var justEntered: bool = false
proc handleMouse*(wnd: PWin) =
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
proc cursorEnterCb(self: PWin, entered: bool) =
  if entered:
    var (x,y) = self.cursorPos
    lastX = x
    lastY = y
    justEntered = true

proc closeCb(wnd: PWin) =
  winDat.del(wnd)

proc AttachInput*(wnd: PWin) =
  wnd.cursorEnterCb = cursorEnterCb
proc pollKeyboard*(self: PWin): input.TKeyCombination =
  for elm in glfw.TKey:
    if self.isKeyDown(elm):
      result.incl(getKey(elm))
    else:
      result.excl(getKey(elm))


  
proc pollMouseAbsolute*(self: PWin): input.TMouse =
  var (x,y) = self.cursorPos
  result.x = x
  result.y = y
  # TODO: include all the mouse buttons
  #       here, not just L and R
  if self.mouseBtnDown(mbLeft):
    result.buttons.incl(input.mbLeft)
  if self.mouseBtnDown(mbRight):
    result.buttons.incl(input.mbRight)

proc pollMouse*(self: PWin): input.TMouse =
  var mouseInfo = pollMouseAbsolute(self)
  var dx = mouseInfo.x - lastx
  var dy = mouseInfo.y - lasty
  if justEntered:
    justEntered = false
    dx = 0
    dy = 0
  lastx = mouseInfo.x
  lasty = mouseInfo.y
  result.x = dx
  result.y = dy
proc pollInput*(self: PWin): input.TInput =
  result.keyboard = pollKeyboard(self)
  result.mouse = pollMouse(self)
proc pollInputAbsolute*(self: PWin): input.TInput =
  result.keyboard = pollKeyboard(self)
  result.mouse = pollMouseAbsolute(self)
