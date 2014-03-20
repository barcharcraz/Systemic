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


iterator matchEntsComponents(scene: SceneId; typ1: typedesc; typ2: typedesc): tuple[a: ptr TComponent[typ1], b: ptr TComponent[typ2]] {.inline.} =
  var comps1 = components(scene, TComponent[typ1])
  var comps2 = components(scene, TComponent[typ2])
  for i1 in 0..comps1.high:
    for i2 in 0..comps2.high:
      if comps1[i1].id == comps2[i2].id:
        yield (addr comps1[i1], addr comps2[i2])
        break
dumpTree:
  iterator matchEntsComponents(scene: SceneId; typ1: typedesc; typ2: typedesc; typ3: typedesc): 
    tuple[a: ptr TComponent[typ1]; b: ptr TComponent[typ2], c: ptr TComponent[typ3]] {.inline.} =
    var comps = components(scene, TComponent[typ3])
    for a,b in matchEntsComponents(scene, typ1, typ2):
      for i in 0..comps.high:
        if comps[i].id == a.id:
          yield (a, b, addr comps[i])
macro makeEntIterator(num: static[int]): stmt {.immediate.} =
  var parms: seq[PNimrodNode]
  newSeq(parms, 0)
  for i in 1..num:
    parms.add(newIdentDefs(newIdentNode(!("typ" & $i)),
      newIdentNode(!"typedesc")))

iterator matchEnts*(scene: SceneId; typ1: typedesc; typ2: typedesc): tuple[a: ptr typ1, b: ptr typ2] {.inline.} =
  var comps1 = components(scene, TComponent[typ1])
  var comps2 = components(scene, TCOmponent[typ2])
  for i1 in 0..comps1.high:
    for i2 in 0..comps2.high:
      yield (addr a[].data, addr b[].data)
#yes these are not ideal but until QuasiQuotes are working again
#it is far too much effort to write the macro required for these,
discard """
proc matchEntHelper(scene: SceneId; curEnt: EntityId; first: typedesc; typ: varargs[expr]): EntityId =    
  for elm in components(scene, TComponent[first]):
    if elm.id == curEnt:
      if typ.len == 1:
        return curEnt
      else:
        return matchEntHelper(scene, curEnt, typ)
    else:
      return -1.EntityId
proc matchEnt*(scene: SceneId; first: typedesc; typ: varargs[expr]): EntityId = 
  for elm in components(scene, TComponent[first]):
    result = matchEntHelper(scene, elm.id, typ)
    if result != -1:
      return 
"""
proc matchEnt*(scene: SceneId; typ1: typedesc): EntityId =
  result = components(scene, TComponent[typ1])[0].id
proc matchEnt*(scene: SceneId; typ1: typedesc; typ2: typedesc): EntityId =
  result = (-1).EntityId
  for elm in components(scene, TComponent[typ1]):
    for typ in components(scene, TComponent[typ2]):
      if typ.id == elm.id:
        return elm.id

proc matchEnt*(scene: SceneId; typ1: typedesc; typ2: typedesc; typ3: typedesc): EntityId =
  result = (-1).EntityId
  for elm1 in components(scene, TComponent[typ1]):
    for elm2 in components(scene, TComponent[typ2]):
      if elm2.id == elm1.id:
        for elm3 in components(scene, TComponent[typ3]):
          if elm3.id == elm2.id:
            return elm1.id
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

