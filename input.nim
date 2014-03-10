import tables
type TUsagePage* = enum
  upUndefined = 00,
  upGenericDesktop = 01
type TUsage* = enum
  usageKeyboard = 0x07,
  usageMouseButton = 0x09
type TKey* = enum
  keyUnknown = 0,
  keyA = 4,
  keyB = 5,
  keyC = 6,
  keyD = 7,
  keyE = 8,
  keyF = 9,
  keyG = 10,
  keyH = 11,
  keyI = 12,
  keyJ = 13,
  keyK = 14,
  keyL = 15,
  keyM = 16,
  keyN = 17,
  keyO = 18,
  keyP = 19,
  keyQ = 20,
  keyR = 21,
  keyS = 22,
  keyT = 23,
  keyU = 24,
  keyV = 25,
  keyW = 26,
  keyX = 27,
  keyY = 28,
  keyZ = 29,
  keyNum0 = 30,
  keyNum1 = 31,
  keyNum2 = 32,
  keyNum3 = 33,
  keyNum4 = 34,
  keyNum5 = 35,
  keyNum6 = 36,
  keyNum7 = 37,
  keyNum8 = 38,
  keyNum9 = 39,
  keyEnter = 40,
  keyEscape = 41,
  keyDelete = 42,
  keyTab = 43,
  keySpace = 44,
  keyMinus = 45,
  keyEquals = 46,
  keyOpenSquare = 47,
  keyCloseSquare = 48,
  keyBackslash = 49,
  keyTildeNonUS = 50,
  keySemicolon = 51,
  keyQuote = 52,
  keyGrave = 53,
  keyComma = 54,
  keyDot = 55,
  keySlash = 56,
  keyCapsLock = 57,
  keyF1 = 58,
  keyF2 = 59,
  keyF3 = 60,
  keyF4 = 61,
  keyF5 = 62,
  keyF6 = 63,
  keyF7 = 64,
  keyF8 = 65,
  keyF9 = 66,
  keyF10 = 67,
  keyF11 = 68,
  keyF12 = 69,
  keyRight = 79,
  keyLeft = 80,
  keyDown = 81,
  keyUp = 82,
  keyNumpad1 = 89,
  keyNumpad2 = 90,
  keyNumpad3 = 91,
  keyNumpad4 = 92,
  keyNumpad5 = 93,
  keyNumpad6 = 94,
  keyNumpad7 = 95,
  keyNumpad8 = 96,
  keyNumpad9 = 97,
  keyNumpad0 = 98,
type TMouseButton = enum
  mbNone = 0
  mbLeft = 1,
  mbRight = 2,
  mbMiddle = 3
const MaxNumAxis = 16
type TKeyCombination* = set[TKey]
type TAxis = float
type TDevice = object
  usage_page: int16
  usage: int16
  device: ref
type TDeviceData = object
  axes: array[0..MaxNumAxis, TAxis]
type TInputMapping* = object
  devices: seq[TDevice]
  axisActions: TTable[string, ptr TAxis]
  actions: TTable[string, TKeyCombination]
type TMouse* = object
  x*: TAxis
  y*: TAxis
  buttons*: set[TMouseButton]
type TKeyboard* = object
  keys*: TKeyCombination
proc initInputMapping*(): TInputMapping =
  result.devices = newSeq[TDevice]()
  result.axisActions = initTable[string, ptr TAxis]()
  result.actions = initTable[string, TKeyCombination]()
proc ActivateKey*(self: var TInputMapping, key: TKey) =
  self.pressed.incl(key)
proc DeactivateKey*(self: var TInputMapping, key: TKey) = 
  self.pressed.excl(key)
proc AddAction*(self: var TInputMapping, name: string, action: TKeyCombination) =
  self.actions.add(name, action)
proc AddAxisAction*(self: var TInputMapping, name: string, action: ptr TAxis) =
  self.axisActions.add(name, action)
proc AxisAction*(self: TInputMapping, name: string): TAxis =
  result = self.axisActions[name]
proc Action*(self: TInputMapping, name: string): bool =
  result = self.actions[name] <= self.pressed
  