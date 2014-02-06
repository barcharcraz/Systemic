type SceneId = int
type TScene* = object
  id*: SceneId
  updateList: seq[proc(id: SceneId)]

proc update(this: TScene) =
  for elm in this.updateList:
    elm(this.id)
