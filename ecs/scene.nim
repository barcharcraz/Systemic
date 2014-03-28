type SceneId* = distinct int
proc `==`*(a,b: SceneId): bool {.borrow.}
type TCallbackInfo* = object
  init*: proc(id: SceneId)
  update*: proc(id: SceneId)
  destroy*: proc(id: SceneId)
  initialized*: set[int16]
proc initCallbackInfo*(update: proc(id: SceneId)): TCallbackInfo =
  result.init = nil
  result.update = update
  result.destroy = nil
type TScene* = object
  id*: SceneId
  updateList: seq[TCallbackInfo]

proc initScene*(): TScene = 
  var id {.global.}: int = 0
  result.id = id.SceneId
  inc(id)
  result.updateList.newSeq(0)

proc addSystem*(scene: var TScene, func: proc(id: SceneId)) =
  scene.updateList.add(initCallbackInfo(func))
proc insertSystem*(scene: var TScene, func: proc(id: SceneId), pos: int = 0) =
  scene.updateList.insert(initCallbackInfo(func), pos)
proc update*(this: var TScene) =
  for i,elm in this.updateList.pairs:
    if not (i.int16 in elm.initialized):
      if elm.init != nil: elm.init(this.id)
      incl(this.updateList[i].initialized, i.int16)
    if elm.update != nil: elm.update(this.id)
