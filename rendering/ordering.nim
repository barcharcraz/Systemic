import ecs
type TOrdering* = distinct int
MakeEntityComponent(TOrdering)

proc OrderingSystem*(scene: SceneId) {.procvar.} =
  var comps = addr components(scene, TComponent[TOrdering])