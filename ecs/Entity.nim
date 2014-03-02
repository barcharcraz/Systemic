
import Scene
import SceneNode

type EntityId* = distinct int
type TComponent*[T] = object
  id: EntityId
  data: T

var EntityMapping: seq[SceneId] = @[]

proc genEntity*(): EntityId = 
  var id {.global.}: int = 0
  result = cast[EntityId](id)
  inc(id)





proc initComponent*[T](id: EntityId; data: T): TComponent[T] =
  result.id = id
  result.data = data
template MakeEntityComponent*(typ: typedesc) =
  MakeComponentNode(TComponent[typ])



proc add*[T](ent: EntityId, elm: T) =
  var component = initComponent(ent, elm)
  var scene: SceneId = EntityMapping[ent.int]
  scene.addComponent(component)

iterator components[T](ent: EntityId): T {.inline.} =
  var scene = EntityMapping[ent]
  for elm in components(scene, TComponent[T]):
    if elm.id == ent:
      yield elm

when isMainModule:
  #MakeEntityComponent(int)
  var TComponent_int_SceneNode = initSceneNode[TComponent[int]]()
  var entitytest = genEntity()
  entitytest.add(4)
  entitytest.add(7)
  
