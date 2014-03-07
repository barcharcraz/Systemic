type SceneId* = distinct int
proc `==`*(a,b: SceneId): bool {.borrow.}
type TScene* = object
  id*: SceneId
  updateList: seq[proc(id: SceneId)]

proc initScene*(): TScene = 
  var id {.global.}: int = 0
  result.id = id.SceneId
  inc(id)
  result.updateList.newSeq(0)

proc addSystem*(scene: var TScene, func: proc(id: SceneId)) =
  scene.updateList.add(func)

proc update*(this: TScene) =
  for elm in this.updateList:
    elm(this.id)
