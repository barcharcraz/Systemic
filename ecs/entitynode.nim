import ecs.scene
import ecs.scenenode
import typetraits
import exceptions
import macros
import ecs.entity
import algorithm
import unittest
import tables

var EntityMapping: seq[SceneId] = @[]


proc add*[T](ent: EntityId, elm: T)
proc add*(ent: EntityId, typ: string, item: pointer)
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
    
var entTypeMapping = initTable[string, proc(ent: EntityId, elm: pointer)]()

template MakeEntityComponent*(typ: expr) =
  bind entTypeMapping
  MakeComponentNode(typ)
  MakeComponentNode(EntityId, genIdentName(typ.name() & "EntityIds"))
  when false:
    entTypeMapping.add(name(typ)) do (ent: EntityId, elm: pointer):
      add(ent, cast[ptr typ](elm)[])

proc entities*(scene: SceneId; typ: typedesc): var seq[EntityId] =
  macro getIdent(): expr =
    result = newIdentNode(!genIdentName(name(typ) & "EntityIds"))
  static: echo(name(typ))
  result = getIdent().sceneList[scene.int]
  if result.isnil:
    getIdent().sceneList[scene.int] = @[]
    result = getIdent().sceneList[scene.int]
proc add*[T](ent: EntityId, elm: T) =
  var scene: SceneId = ent.getScene
  static: echo(name(T))
  var ents = addr entities(scene, type(elm))
  var comps = addr components(scene, type(elm))
  assert(ents[].len == comps[].len)
  ents[].add(ent)
  comps[].add(elm)

proc add*(ent: EntityId, typ: string, item: pointer) =
  entTypeMapping[typ](ent, item)

proc del*[T](ent: EntityId, typ: typedesc[T]) =
  var scene = ent.getScene()
  var comps = addr components(scene, TComponent[T])
  var idx = 0
  for i,elm in comps[].pairs():
    if elm.id == ent:
      idx = i
      break
  comps[].del(idx)

iterator components*(ent: EntityId, typ: typedesc): typ {.inline.} =
  var scene = EntityMapping[ent.int]
  for elm in components(scene, TComponent[typ]):
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
proc `?`*(ent: EntityId, typ: typedesc): ptr typ =
  var ents = entities(getScene(ent), typ)
  var comps = components(getScene(ent), typ)
  proc `<`(a: EntityId, b: EntityId): bool = a.int < b.int
  var idx = binarySearch(ents, ent)
  if idx == -1: return nil
  return addr comps[idx]
proc `@`*(ent: EntityId, typ: typedesc): var typ =
  result = (ent?typ)[]
proc mEntFirstOpt*[T: HasEntComponent](ent: EntityId): ptr T =
  var defNode = addr GetDefaultNode[TComponent[T]]()
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



iterator walk*(scene: SceneId; typ1: typedesc): auto {.inline.} =
  var ents = addr entities(scene, typ1)
  var comps = addr components(scene, typ1)
  for i,elm in comps[]:
    yield (ents[i], addr comps[i])
iterator walk*(scene: SceneId; typ1, typ2: typedesc): auto {.inline.} =
  var ents = addr entities(scene, typ2)
  var comps = addr components(scene, typ2)
  for id, a in walk(scene, typ1):
    for i in 0..comps[].high:
      if ents[i] == id:
        yield (id, a, addr comps[i])
      if ents[i].int > id.int:
        break
iterator walk*(scene: SceneId; typ1, typ2, typ3: typedesc): auto {.inline.} =
  var ents = addr entities(scene, typ3)
  var comps = addr components(scene, typ3)
  for id, a, b in walk(scene, typ1, typ2):
    for i in 0..comps[].high:
      if ents[i] == id:
        yield (id, a, b, addr comps[i])
      if ents[i].int > id.int:
        break
iterator walk*(scene: SceneId; typ1, typ2, typ3, typ4: typedesc): auto {.inline.} =
  var ents = entities(scene, typ4)
  var comps = components(scene, typ4)
  for id, a, b, c in walk(scene, typ1, typ2):
    for i in 0..comps[].high:
      if ents[i] == id:
        yield (id, a, b, c, addr comps[i])
      if ents[i].int > id.int:
        break
#procs to add a system that takes a tuple of entities, these
#are quite useful for more scripty code
proc addSystem*[Ta](scene: SceneId; func: proc(id: SceneId; tup: tuple[a: ptr Ta])) =
  scene.addSystem do (id: SceneId):
    for elm in walk(id, Ta):
      func(scene, (elm))
proc addSystem*[Ta, Tb](scene: SceneId; func: proc(id: SceneId; tup: tuple[a: ptr Ta, b: ptr Tb])) =
  scene.addSystem do (id: SceneId):
    for a,b in walk(id, Ta, Tb):
      func(scene, (a,b))
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
    for idx, intc, charc in testScene.id.walk(int, char):
      if intc[] == 3 and charc[] == '3':
        got33 = true
    check(got33)
  #test("tMwalkOpt"):
  #  var walker = mWalkOpt(testScene.id, int, float32, string)
  #  var comps = components(testScene.id, TComponent[int])
  #  for elm in comps:
  #    var (i, f, s) = walker(elm.id)
  #    echo(i, f)

