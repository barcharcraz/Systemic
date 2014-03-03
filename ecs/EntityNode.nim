
import Scene
import SceneNode
import typetraits
import exceptions
import macros
import entity

var EntityMapping: seq[SceneId] = @[]



proc mgetScene(ent: EntityId): var SceneId =
  if EntityMapping.high < ent.int:
    raise newException(ENoScene, $(ent.int))
  result = EntityMapping[ent.int]
proc getScene(ent: EntityId): SceneId =
  result = mgetScene(ent)
  if result == SceneId(-1):
    raise newException(ENoScene, $(ent.int))

proc add(scene: SceneId; ent: EntityId) =
  #make sure that we have enough space in the entity mapping
  #if we do not than add more space and set all the new elements
  #to -1
  if EntityMapping.high < ent.int:
    var oldLen = EntityMapping.len
    EntityMapping.setLen(ent.int + 1)
    for elm in oldLen..EntityMapping.high:
      EntityMapping[elm] = SceneId(-1)
  var entscene = mgetScene(ent)
  if entscene != SceneId(-1):
    #this means that the entity is already in a scene
    #now there is nothing preventing us from letting
    #an entity be in more than one scene but it would mean
    #another dimension in the EntityMapping
    raise newException(ESceneNotUnique, "Entity: " & $ent.int & " is already in scene " & $entscene.int)
  mgetScene(ent) = scene
    


template MakeEntityComponent*(typ: expr) {.immediate,dirty.} =
  MakeComponentNode(TComponent[typ])



proc add*[T](ent: EntityId, elm: T) =
  var component = initComponent(ent, elm)
  var scene: SceneId = ent.getScene
  scene.addComponent(component)

iterator components*[T](ent: EntityId): T {.inline.} =
  var scene = EntityMapping[ent.int]
  for elm in components(scene, TComponent[T]):
    if elm.id == ent:
      yield elm.data

when isMainModule:
  MakeEntityComponent(int)
  #var TComponent_int_SceneNode = initSceneNode[TComponent[int]]()
  var entitytest = genEntity()
  var otherEntity = genEntity()
  var testScene = initScene()
  testScene.id.add(entitytest)
  testScene.id.add(otherEntity)
  echo repr(EntityMapping)
  entitytest.add(4)
  entitytest.add(7)
  otherEntity.add(1)
  otherEntity.add(2)
  echo "all ints"
  for elm in testScene.components(TComponent[int]):
    echo elm.data
  echo "test ent ints"
  for elm in components[int](entitytest):
    echo elm
  echo "other ent ints"
  for elm in components[int](otherEntity):
    echo elm
  
  
