
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
    


template MakeEntityComponent*(typ: expr) =
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

type HasEntComponent = generic x
  compiles(GetDefaultNode[TComponent[x]]())

proc hasEnt(comps: seq[pointer], ent: EntityId): bool =
  type TBaseComp = object
    id: EntityId
  for elm in comps:
    #here we rely on structural compatibility
    var baseComp: TBaseComp = cast[TBaseComp](elm)
    if baseComp.id == ent:
      return true
  return false

proc mEntFirstOpt*[T: HasEntComponent](ent: EntityId): ptr T =
  var comps = addr components(ent.getScene(), TComponent[T])
  for i in 0..high(comps[]):
    if comps[][i].id == ent:
      return addr comps[][i].data
proc mEntFirst*[T: HasEntComponent](ent: EntityId): var T =
  when compiles(GetDefaultNode[TComponent[T]]()):
    var resPtr = mEntFirstOpt[T](ent)
    if resPtr == nil:
      raise newException(ENoSuchComponent, typetraits.name(T))
    result = resPtr[]

proc entFirst*[T: HasEntComponent](ent: EntityId): T =
  when compiles(GetDefaultNode[TComponent[T]]()):
    result = mEntFirst[T](ent)

proc mgetAny*[T](scene: SceneId): var T =
  when compiles(GetDefaultNode[T]()):
    return SceneNode.mfirst[T](scene)
  when compiles(GetDefaultNode[TComponent[T]]()):
    return SceneNode.mfirst[TComponent[T]](scene).data

proc getAny*[T](scene: SceneId): T =
  result = mgetAny[T](scene)

proc matchEnt(scene: SceneId; types: varargs[pointer]): EntityId =
  #static: echo typetraits.name(types[0])
  #var firstComps = types[0]
  for elm in types[0]:
    var hasFailed = false
    for typ in types:
      if hasEnt(typ, elm.id):
        hasFailed = true
        break
    if hasFailed == false:
      return elm.id
  return (-1).EntityId
when isMainModule:
  MakeEntityComponent(int)
  MakeEntityComponent(float32)
  #var TComponent_int_SceneNode = initSceneNode[TComponent[int]]()
  var entitytest = genEntity()
  var otherEntity = genEntity()
  var testScene = initScene()
  testScene.id.add(entitytest)
  testScene.id.add(otherEntity)
  echo repr(EntityMapping)
  entitytest.add(4)
  entitytest.add(7)
  entitytest.add(1.0'f32)
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
  echo "noncomponent mfirst test"
  var testInt: int = mEntFirst[int](entitytest.EntityId)
  echo($testInt)
  echo "noncomponent first test"
  var testInt1 = entFirst[int](entitytest.EntityId)
  echo($testInt1)
  echo "mget any test"
  var testInt2 = mgetAny[int](testScene.id)
  echo($testInt2)
  echo "get any test"
  var testInt3 = getAny[int](testScene.id)
  echo($testInt3)
  echo "test entity search"
  echo(matchEnt(testScene.id, addr GetDefaultNode[TComponent[int]], addr GetDefaultNode[TComponent[float]]).int)
  
  
