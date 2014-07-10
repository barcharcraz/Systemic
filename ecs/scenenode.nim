import ecs.scene
import macros
import typetraits
import strutils
import ecs.entity
import algorithm
import tables
type TSceneNode*[T] = object
  sceneList*: seq[seq[T]]
type TSceneNodeVtbl = object
  clear: proc()

var AllSceneNodes: seq[TSceneNodeVtbl] = @[]

proc components*(scene: SceneId; typ: typedesc): var seq[typ]


proc ClearAll*() =
  for vtbl in AllSceneNodes:
    vtbl.clear()
    resetEntityGen()
    resetSceneGen()
    clearEntMapping()

proc initSceneNode*[T](): TSceneNode[T] = 
  newSeq(result.sceneList, 10)

#proc addComponent*[T](scene: SceneId, item: T)

proc addToNode*[T](node: var TSceneNode[T], scene: SceneId, item: T) =
  if node.sceneList.len <= scene.int:
    #we need to use this version of newseq to work
    #around a compiler bug
    var toInst: seq[T]
    newSeq(toInst, 0)
    node.sceneList.insert(toInst, scene.int)
  if node.sceneList[scene.int].isnil:
    newSeq(node.sceneList[scene.int], 0)
  node.sceneList[scene.int].add(item)
proc genIdentName*(name: string): string {.compileTime.}=
  ## This procdeure takes a string and munges it
  ## so that it is a valid identifier name
  ## in particular it replaces [, ], and " " with
  ## "" (nothing).
  result = name.replace("[", "")
  result = result.replace("]", "")
  result = result.replace(" ", "")
macro concatName(name: static[string]): expr =
  var resultString: string = name & "SceneNode"
  resultString = genIdentName(resultString)
  echo(resultString)
  result = newIdentNode(!resultString)
proc GetDefaultNode*[T](): var TSceneNode[T] =
  result = concatName(typetraits.name(T))
proc GetDefaultNode*[T](name: static[string]): var TSceneNode[T] =
  result = concatName(name)

macro MakeComponentNode*(typ: expr, name: static[string]): stmt =
  var brackets = newNimNode(nnkBracketExpr)
  brackets.add(newIdentNode(!"initSceneNode"))
  brackets.add(typ)
  var identDefs = newNimNode(nnkIdentDefs)
  var postfix = newNimNode(nnkPostfix)
  postfix.add(newIdentNode(!"*"))
  var nameIdent = newIdentNode(name)
  postfix.add(nameIdent)
  identDefs.add(postfix)
  identDefs.add(newNimNode(nnkEmpty))
  var initCall = newNimNode(nnkCall)
  initCall.add(brackets)
  identDefs.add(initCall)
  result = newNimNode(nnkStmtList)
  result.add(newNimNode(nnkVarSection).add(identDefs))
  result.add(quote do:
    var vtbl: TSceneNodeVtbl
    vtbl.clear = proc() =
      `nameIdent` = initSceneNode[`typ`]()
    AllSceneNodes.add(vtbl))
      



macro MakeComponentNode*(typ: expr): stmt =
  var nodeName: string = repr(typ) & "SceneNode"
  echo nodeName
  nodeName = genIdentName(nodeName)
  
  result = getAst(MakeComponentNode(typ, nodeName))

template MakeComponent*(typ: expr) =
  MakeComponentNode(typ)
  when false:
    typeMapping.add(name(typ)) do (scene: SceneId, elm: pointer):
      addComponent(scene, cast[ptr typ](elm)[])

#proc addComponent*[T](scene: TScene, item: T) = 
#  GetDefaultNode[T]().addToNode(scene.id, item)
#proc addComponent*[T](scene: SceneId; item: T) =
#  echo name(T)
#  GetDefaultNode[T]().addToNode(scene, item)
#proc deleteComponent*[T](scene: SceneId; typ: typedesc[T]; idx: int) =
#  GetDefaultNode[T]().sceneList[scene.int].del(idx)
##gets the sequence of typ components in the given scene
template getComponent*(scene: TScene, typ: expr): expr = 
  GetDefaultNode[typ]().sceneList[scene.id]
##alias for getComponent

#iterator components*[T](scene: SceneId): T {.inline.} = GetDefaultNode[T]().sceneList[scene.int]().items
#iterator components*[T](scene: TScene): T {.inline.} = components[T](scene.id)
#template components*(scene: SceneId, typ: expr): expr = GetDefaultNode[typ]().sceneList[scene.int]
#template components*(scene: TScene, typ: expr): expr = components(scene.id, typ)
proc components*(scene: SceneId; typ: typedesc): var seq[typ] = 
  result = GetDefaultNode[typ]().sceneList[scene.int]
  if result.isnil:
    GetDefaultNode[typ]().sceneList[scene.int] = @[]
    result = GetDefaultNode[typ]().sceneList[scene.int]
##functions to deal with adding systems to scenes, these
##are designed so that you can add a proc with the signature
##`proc(id: SceneId; comps: openarray[T])` or `proc(id: SceneId; x: T)` can be added to a
##scene.

##type class that matches everything that is not an openarray
type notArray = generic x
  not (x is openarray)
proc addSystem*[T](scene: var TScene, func: proc(id: SceneId, ts: openarray[T])) =
  scene.addSystem do (id: SceneId):
    func(id, GetDefaultNode[T]().sceneList[id.int])

proc addSystem*[T: notArray](scene: var TScene, func: proc(id: SceneId, t: T)) =
  scene.addSystem do (id: SceneId):
    for elm in components(id, T):
      func(id, elm)

##these versions of the addSystem proc use var params
proc addSystem*[T: notArray](scene: var TScene, func: proc(id: SceneId; t: var T)) =
  scene.addSystem do (id: SceneId):
    var comps = addr components(id, T)
    for i in 0..comps[].high:
      func(id, comps[][i])

##these versions of the addSystem procdeure are for adding functions that
##do not need to know about what scene they are being run on
proc addSystem*[T](scene: var TScene, func: proc(ts: openarray[T])) =
  scene.addSystem do (id: SceneId):
    func(GetDefaultNode[T]().sceneList[id.int])
proc addSystem*[T](scene: var TScene, func: proc(ts: var openarray[T])) =
  scene.addSystem do (id: SceneId):
    func(GetDefaultNode[T]().sceneList[id.int])
proc addSystem*[T: notArray](scene: var TScene; func: proc(t: T)) =
  scene.addSystem do (id: SceneId):
    for elm in components(id, T):
      func(elm)

proc addSystem*(scene: var TScene; func: proc()) =
  ## adds a system to scene that is run once per frame
  ## and does not need to know anything at all about
  ## the scene
  scene.addSystem do (id: SceneId):
    func()

type HasComponent = generic x
  compiles(GetDefaultNode[x]())
##functions to get a component given a scene
##these will just fetch the first component
##of the given type
proc mfirst*[T: HasComponent](scene: SceneId): var T =
  when compiles(GetDefaultNode[T]()):
    var comps = addr components(scene, T)
    result = comps[][0]
proc first*[T: HasComponent](scene: SceneId): T =
  when compiles(GetDefaultNode[T]()):
    result = mfirst[T](scene)    

when isMainModule:
  proc testSystem(id: SceneId, ints: openarray[int]) =
    for elm in ints:
      echo elm
  proc testIndividualSystem(id: SceneId, i: int) =
    echo i
  MakeComponent(int)
  var testScene = initScene()
  testScene.addComponent(4)
  testScene.addComponent(5)
  echo "testing components function"
  for elm in components(testScene, int):
    echo elm
  echo "testing SystemWrapper"
  addSystem(testScene, testSystem)
  addSystem(testScene, testIndividualSystem)
  testScene.update()
  echo "testing mfirst"
  echo mfirst[int](testScene.id)
  echo "testing first"
  echo first[int](testScene.id)
  echo compiles(GetDefaultNode[int]())
  
  
