import ecs.scene
import ecs.scenenode
import typetraits
import exceptions
import macros
import ecs.entity
import unittest

var EntityMapping: seq[SceneId] = @[]



proc mgetScene*(ent: EntityId): var SceneId =
  if EntityMapping.high < ent.int:
    raise newException(ENoScene, $(ent.int))
  result = EntityMapping[ent.int]
proc getScene*(ent: EntityId): SceneId =
  result = mgetScene(ent)
  if result == SceneId(-1):
    raise newException(ENoScene, $(ent.int))

proc add*(scene: SceneId; ent: EntityId) =
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
  var defNode = GetDefaultNode[TComponent[T]]()
  if defNode.sceneList.len <= ent.getScene().int:
    return nil
  if defNode.sceneList[ent.getScene().int].isnil:
    return nil
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


iterator matchEntsComponents*(scene: SceneId; typ1: typedesc): auto {.inline.} =
  var comps = components(scene, TComponent[typ1])
  static: echo(typ1.name())
  for i in comps.low..comps.high:
    yield (addr comps[i])
iterator matchEntsComponents*(scene: SceneId; typ1: typedesc; typ2: typedesc): auto {.inline.} =
  var comps = components(scene, TComponent[typ2])
  for elm in matchEntsComponents(scene, typ1):
    for i1 in 0..comps.high:
      if comps[i1].id == elm.id:
        yield (elm, addr comps[i1])
        break

iterator matchEntsComponents*(scene: SceneId; typ1: typedesc; typ2: typedesc; typ3: typedesc): auto {.inline.} =
  var comps = components(scene, TComponent[typ3])
  for a,b in matchEntsComponents(scene, typ1, typ2):
    for i in 0..comps.high:
      if comps[i].id == a.id:
        yield (a, b, addr comps[i])
iterator matchEnts*(scene: SceneId; typ1: typedesc): auto {.inline.} =
  for a in matchEntsComponents(scene, typ1):
    yield (addr a[].data)
iterator matchEnts*(scene: SceneId; typ1: typedesc; typ2: typedesc): auto {.inline.} =
  for a,b in matchEntsComponents(scene, typ1, typ2):
    yield (addr a[].data, addr b[].data)
iterator matchEnts*(scene: SceneId; typ1: typedesc; typ2: typedesc; typ3: typedesc): auto {.inline.} =
  for a,b,c in matchEntsComponents(scene, typ1, typ2, typ3):
    yield (addr a[].data, addr b[].data, addr c[].data)
proc matchEnt*(scene: SceneId; tup: var tuple[a: distinct auto]) =
  for a in matchEntsComponents(scene type(tup.a)):
    tup = (addr a[].data)
    return
proc matchEnt*(scene: SceneId; tup: var tuple[a: distinct auto, b: distinct auto]) =
  for a,b in matchEntsComponents(scene, type(tup.a), type(tup.b)):
    tup = (addr a[].data, addr b[].data)
    return
proc matchEnt*(scene: SceneId; typ1: typedesc): EntityId =
  for elm in matchEntsComponents(scene, typ1):
    return elm.id
proc matchEnt*(scene: SceneId; typ1: typedesc; typ2: typedesc): EntityId =
  result = EntityId(-1)
  for a,b in matchEntsComponents(scene, typ1, typ2):
    assert(a.id == b.id)
    return a.id
proc matchEnt*(scene: SceneId; typ1: typedesc; typ2: typedesc; typ3: typedesc): EntityId =
  result = EntityId(-1)
  for a,b,c in matchEntsComponents(scene, typ1, typ2, typ3):
    assert(a.id == b.id and a.id == c.id)
    return a.id

when isMainModule:
  MakeEntityComponent(int)
  MakeEntityComponent(char)
  MakeEntityComponent(float32)
  MakeEntityComponent(string)
  #var TComponent_int_SceneNode = initSceneNode[TComponent[int]]()
  var entitytest = genEntity()
  var otherEntity = genEntity()
  var thirdEntity = genEntity()
  var testScene = initScene()
  testScene.id.add(entitytest)
  testScene.id.add(otherEntity)
  testScene.id.add(thirdEntity)
  echo repr(EntityMapping)
  entitytest.add(4)
  entitytest.add(7)
  entitytest.add(1.0'f32)
  otherEntity.add(1)
  otherEntity.add(2)
  otherEntity.add('a')
  otherEntity.add("foo")
  thirdEntity.add(3)
  thirdEntity.add('3')
  
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
  test("tEntSearchOne"): check(matchEnt(testScene.id, string).int == 1)
  test("tEntSearch"): check(matchEnt(testScene.id, int, float32).int == 0)
  test("tEntSearchInv"): check(matchEnt(testScene.id, char, float32).int == -1)
  test("tEntSearchthree"): check(matchEnt(testScene.id, char, string, int).int == 1)
  test("tMathcEntTuple"):
    var got33: bool = false
    for intc, charc in testScene.id.matchEnts(int, char):
      if intc[] == 3 and charc[] == '3':
        got33 = true
    check(got33)

