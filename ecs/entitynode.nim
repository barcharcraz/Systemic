import ecs.scene
import ecs.scenenode
import typetraits
import exceptions
import macros
import ecs.entity
import algorithm
import tables

proc add*[T](ent: EntityId, elm: T)
proc add*(ent: EntityId, typ: string, item: pointer)
#{{{ ----- debug verification functions -----------
proc verifyNoDups[T](a: openarray[T]): bool =
  var a: seq[T] = @a
  sort(a) do (a,b: EntityId) -> int: system.cmp[int](a.int, b.int)
  var dups: seq[T] = @[]
  var i: int = a.low.int
  while i < a.high:
    if a[i] == a[i+1]:
      dups.add(a[i])
      while a[i] == a[i+1]:
        inc(i)
    inc(i)
  if dups.len > 0:
    return false
  return true
proc verifySorted(a: seq[EntityId]): bool =
  var b = a
  sort(b) do (a,b) -> auto: system.cmp(a.int, b.int)
  result = a == b
#}}}

    
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
    result = newIdentNode(!(genIdentName(name(typ) & "EntityIds")))
  result = getIdent().sceneList[scene.int]
  if result.isnil:
    getIdent().sceneList[scene.int] = @[]
    result = getIdent().sceneList[scene.int]
  assert(verifyNoDups(result))
  assert(verifySorted(result))
proc add*[T](ent: EntityId, elm: T) =
  var scene: SceneId = ent.getScene
  var ents = addr entities(scene, type(elm))
  var comps = addr components(scene, type(elm))
  assert(ents[].len() == comps[].len())
  ents[].add(ent)
  comps[].add(elm)
  assert(verifyNoDups(ents[]))
  assert(verifySorted(ents[]))

proc add*(ent: EntityId, typ: string, item: pointer) =
  entTypeMapping[typ](ent, item)

proc add*[T](scene: SceneId, item: T): EntityId {.discardable.} =
  result = genEntity()
  add(scene, result)
  result.add(item)

proc del*[T](ent: EntityId, typ: typedesc[T]) =
  var scene = ent.getScene()
  var ents = addr entities(scene, T)
  var comps = addr components(scene, T)
  var idx = 0
  for i,elm in ents[].pairs():
    if elm == ent:
      idx = i
      break
  comps[].del(idx)
  ents[].del(idx)
proc clear*[T](scene: SceneId, typ: typedesc[T]) =
  components(scene, T) = @[]
  entities(scene, T) = @[]
iterator components*(ent: EntityId, typ: typedesc): typ {.inline.} =
  var scene = ent.getScene()
  for elm in components(scene, TComponent[typ]):
    if elm.id == ent:
      yield elm.data

proc `?`*(ent: EntityId, typ: typedesc): ptr typ =
  var ents = addr entities(getScene(ent), typ)
  var comps = addr components(getScene(ent), typ)
  proc `<`(a: EntityId, b: EntityId): bool = a.int < b.int
  var idx = binarySearch(ents[], ent)
  if idx == -1: return nil
  return addr comps[idx]
proc `@`*(ent: EntityId, typ: typedesc): var typ =
  result = (ent?typ)[]

proc createDefault(id: EntityId, typ: typedesc) =
  var newT: typ
  id.add(newT)

iterator walk*(scene: SceneId; typ1: typedesc, create: bool = false): auto {.inline.} =
  var ents = addr entities(scene, typ1)
  var comps = addr components(scene, typ1)
  for i,elm in comps[]:
    yield (ents[i], addr comps[i])
iterator walk*(scene: SceneId; typ1, typ2: typedesc, create: bool = false): auto {.inline.} =
  var ents = addr entities(scene, typ2)
  var comps = addr components(scene, typ2)
  for id, a in walk(scene, typ1, create):
    if comps[].len == 0 and create:
      createDefault(id, typ2)
    for i in 0..comps[].high:
      if ents[i] == id:
        yield (id, a, addr comps[i])
      if ents[i].int > id.int:
        if create:
          createDefault(id, typ2)
          yield(id, a, addr comps[i])
        break
iterator walk*(scene: SceneId; typ1, typ2, typ3: typedesc, create: bool = false): auto {.inline.} =
  var ents = addr entities(scene, typ3)
  var comps = addr components(scene, typ3)
  for id, a, b in walk(scene, typ1, typ2, create):
    if comps[].len == 0 and create:
      createDefault(id, typ3)
    for i in 0..comps[].high:
      if ents[i] == id:
        yield (id, a, b, addr comps[i])
      if ents[i].int > id.int:
        if create:
          createDefault(id, typ3)
          yield (id, a, b, addr comps[i])
        break
iterator walk*(scene: SceneId; typ1, typ2, typ3, typ4: typedesc, create: bool = false): auto {.inline.} =
  var ents = addr entities(scene, typ4)
  var comps = addr components(scene, typ4)
  for id, a, b, c in walk(scene, typ1, typ2, typ3, create):
    if comps[].len == 0 and create:
      createDefault(id, typ4)
    for i in 0..comps[].high:
      if ents[i] == id:
        assert(a != nil)
        assert(b != nil)
        assert(c != nil)
        assert(addr comps[i] != nil)
        yield (id, a, b, c, addr comps[i])
      if ents[i].int > id.int:
        if create:
          createDefault(id, typ4)
          yield (id, a, b, c, addr comps[i])
        break
discard """
proc next*(scene: SceneId, typ: typedesc): iterator(id: EntityId): ptr typ =
  result = iterator(id: EntityId): ptr typ =
    var lastId = id
    for newId, elm in walk(scene, typ):
      if newId == id:
        lastId = id
        yield elm
      assert(lastId.int < id.int)
"""
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
  import unittest
  import math
  MakeEntityComponent(int)
  MakeEntityComponent(char)
  MakeEntityComponent(float32)
  MakeEntityComponent(string)
  #var TComponent_int_SceneNode = initSceneNode[TComponent[int]]()
  suite "int basics":
    setup:
      var testScene = initScene()
      var allents: seq[EntityId] = @[]
      for i in 0..100:
        allents.add(genEntity())
        testScene.id.add(allents[allents.high])
      randomize(0)
      for i in 0..100:
        allents[i].add(i)
      for i in 100..0:
        if i mod 2 == 0:
          allents[i].add(i.float32)
      var ents = entities(testScene.id, int)
      var comps = components(testScene.id, int)
    teardown:
      clearAll()
    test "tlen":
      check(ents.high == comps.high)
      check(ents.low == comps.low)
      check(ents.len == comps.len)
    test "tAligned":
      for i in ents.low..ents.high:
        check(ents[i].int == comps[i])
    test "tWalk":
      for i, ival, fval in walk(testScene.id, int, float32):
        check(fval[].int == ival[])
  
  

