type SceneId* = int
type TScene* = object
  id*: SceneId
  updateList: seq[proc(id: SceneId)]

proc initScene*(): TScene = 
  var id {.global.}: int = 0
  result.id = id
  inc(id)
  result.updateList.newSeq(10)

proc update*(this: TScene) =
  for elm in this.updateList:
    elm(this.id)
