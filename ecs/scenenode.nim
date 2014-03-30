import ecs.scene
import macros
import typetraits
import strutils
import ecs.entity
import algorithm
type TSceneNode*[T] = object
  sceneList*: seq[seq[T]]
proc initSceneNode*[T](): TSceneNode[T] = 
  newSeq(result.sceneList, 10)

type notComponent = generic x
  not (x is TComponent)
proc addToNode*[T: notComponent](node: var TSceneNode[T], scene: SceneId, item: T) =
  if node.sceneList.len <= scene.int:
    #we need to use this version of newseq to work
    #around a compiler bug
    var toInst: seq[T]
    newSeq(toInst, 4)
    node.sceneList.insert(toInst, scene.int)
  if node.sceneList[scene.int].isnil:
    newSeq(node.sceneList[scene.int], 0)
  node.sceneList[scene.int].add(item)
proc addToNode*(node: var TSceneNode, scene: SceneId, item: TComponent) =
  if node.sceneList.len <= scene.int:
    var toInst: seq[type(item)]
    newSeq(toInst, 4)
    node.sceneList.insert(toInst, scene.int)
  if node.sceneList[scene.int].isnil:
    newSeq(node.sceneList[scene.int], 0)
  var list = addr node.sceneList[scene.int]
  var insertPos = lowerBound(list[], item) do (a,b)->auto:
    result = system.cmp(a.id.int, b.id.int)
  node.sceneList[scene.int].insert(item, insertPos)
macro concatName(name: static[string]): expr =
  var resultString: string = name & "SceneNode"
  resultString = resultString.replace("[", "")
  resultString = resultString.replace("]", "")
  resultString = resultString.replace(" ", "")
  echo(resultString)
  result = newIdentNode(!resultString)
proc GetDefaultNode*[T](): var TSceneNode[T] =
  result = concatName(typetraits.name(T))
proc GetDefaultNode*[T](name: static[string]): var TSceneNode[T] =
  result = concatName(name)
macro MakeComponentNode*(typ: expr): stmt =
  var nodeName = repr(typ) & "SceneNode"
  nodeName = nodeName.replace("[", "")
  nodeName = nodeName.replace("]", "")
  nodeName = nodeName.replace(" ", "")
  var brackets = newNimNode(nnkBracketExpr)
  brackets.add(newIdentNode(!"initSceneNode"))
  brackets.add(typ)
  var identDefs = newNimNode(nnkIdentDefs)
  var postfix = newNimNode(nnkPostfix)
  postfix.add(newIdentNode(!"*"))
  postfix.add(newIdentNode(nodeName))
  identDefs.add(postfix)
  identDefs.add(newNimNode(nnkEmpty))
  var initCall = newNimNode(nnkCall)
  initCall.add(brackets)
  identDefs.add(initCall)
  result = newNimNode(nnkStmtList)
  result.add(newNimNode(nnkVarSection).add(identDefs))


template MakeComponent*(typ: expr) {.immediate,dirty.} =
  MakeComponentNode(typ)

proc addComponent*[T](scene: TScene, item: T) = 
  GetDefaultNode[T]().addToNode(scene.id, item)
proc addComponent*[T](scene: SceneId; item: T) =
  echo name(T)
  GetDefaultNode[T]().addToNode(scene, item)
##gets the sequence of typ components in the given scene
template getComponent*(scene: TScene, typ: expr): expr = 
  GetDefaultNode[typ]().sceneList[scene.id]
##alias for getComponent

#iterator components*[T](scene: SceneId): T {.inline.} = GetDefaultNode[T]().sceneList[scene.int]().items
#iterator components*[T](scene: TScene): T {.inline.} = components[T](scene.id)
#template components*(scene: SceneId, typ: expr): expr = GetDefaultNode[typ]().sceneList[scene.int]
template components*(scene: TScene, typ: expr): expr = components(scene.id, typ)
proc components*(scene: SceneId; typ: typedesc): var seq[typ] = 
  result = GetDefaultNode[typ]().sceneList[scene.int]
  if result.isnil:
    var toinst: seq[typ]
    newSeq(toInst, 4)
    GetDefaultNode[typ]().sceneList.insert(toInst, scene.int)
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

proc addSystem*[T: notArray](scene: var TScene; func: proc(t: T)) =
  scene.addSystem do (id: SceneId):
    for elm in components(id, T):
      func(elm)


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
  
  
