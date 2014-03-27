import entity
import entitynode
import scene
import scenenode
import unsigned
type TOrdering* = object
  buffer: seq[uint8]
  callbacks: seq[TCallbackInfo]
type TOrderedCallback* = object
  init: proc(scene: SceneId)
  update: proc(scene: SceneId, z: var openarray[uint8])
  destroy: proc(scene: SceneId)
  initialized: set[int]
  order: int
proc initOrderedCallback(update: proc(scene: SceneId, z: var openarray[uint8])): TOrderedCallback =
  result.init = nil
  result.update = update
  result.destroy = nil
  result.initialized = {:}
  result.order = 0
proc add*(self: TOrdering; callbk: TOrderedCallback) =
  self.callbacks.add(callbk)
proc updateOrdered*(self: var TOrderedCallback; scene: SceneId) =
  var numEnts = getNumIds()
  if self.buffer.len < numEnts:
    self.buffer.setLen(numEnts)
  for elm in buffer:
    elm = 0
  for i, elm in self.callbacks.pairs:
    if not(i in self.initialized):
      if elm.init != nil: elm.init(scene)
      incl(self.initialized, i)
    if elm.update != nil: elm.update(scene, self.buffer)
proc OrderingSystem*(scene: SceneId) {.procvar.} =
  var comps = addr components(scene, TComponent[TOrdering])
  var numEnts = getNumIds()
  if comps.len < numEnts:
    comps.setLen(numEnts)
  #this could be a memset, but for now
  #this is safer
  for elm in comps:
    elm = 0
