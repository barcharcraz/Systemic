from input import nil
import glfw/glfw
import glfw/wrapper
import tables
import logging
var winDat = initTable[PWnd, seq[ptr input.TInputMapping]]()
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
  var winData = addr winDat.mget(o)
  if winData == nil:
    return
  for i in 0..winData[].high:
    var inputkey = getKey(key)
    if inputkey != input.keyUnknown:
      input.ActivateKey(winData[i], inputKey)
    else:
      info("Unknown key: " & $key)

proc closeCb(wnd: PWnd) =
  winDat.del(wnd)

proc AttachInput*(wnd: PWnd; inp: var input.TInputMapping) =
  wnd.keyCb = keyCb
  wnd.wndCloseCb = closeCb
  if not winDat.hasKey(wnd):
    winDat.add(wnd, nil)
    newSeq(winDat.mget(wnd), 0)
  winDat.mget(wnd).add(addr inp)
proc DetachInput*(wnd: PWnd; inp: var input.TInputMapping) =
  if not winDat.hasKey(wnd):
    info("window does not have any attached input maps")
    return
  if winDat.mget(wnd) == nil:
    info("window does not have any attached input maps")
    winDat.del(wnd)
    return
  var idx = winDat.mget(wnd).find(addr inp)
  if idx == -1:
    info("tried to remove an input map that was not attached")
    return
  winDat.mget(wnd).del(idx)
