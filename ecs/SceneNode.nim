import Scene
import macros
import typetraits
type TSceneNode*[T] = object
  sceneList: seq[seq[T]]
proc initSceneNode*[T](): TSceneNode[T] = 
  newSeq(result.sceneList, 10)

proc addToNode[T](node: var TSceneNode[T], scene: SceneId, item: T) =
  if node.sceneList.len <= scene:
    #we need to use this version of newseq to work
    #around a compiler bug
    var toInst: seq[T]
    newSeq(toInst, 4)
    node.sceneList.insert(toInst, scene)
  if node.sceneList[scene] == nil:
    newSeq(node.sceneList[scene], 0)
  node.sceneList[scene].add(item)

proc GetDefaultNode[T](): var TSceneNode[T] =
  macro concatName(name: static[string]): expr =
    result = newIdentNode(!(name & "SceneNode"))
  result = concatName(T.name)

macro MakeComponentNode(typ: expr): stmt =
  var nodeName = repr(typ) & "SceneNode"
  var brackets = newNimNode(nnkBracketExpr)
  brackets.add(newIdentNode(!"initSceneNode"))
  brackets.add(newIdentNode(!(repr(typ))))
  var identDefs = newNimNode(nnkIdentDefs)
  identDefs.add(newIdentNode(nodeName))
  identDefs.add(newNimNode(nnkEmpty))
  var initCall = newNimNode(nnkCall)
  initCall.add(brackets)
  identDefs.add(initCall)
  result = newNimNode(nnkStmtList)
  result.add(newNimNode(nnkVarSection).add(identDefs))


template MakeComponent*(typ: typedesc) =
  MakeComponentNode(typ)

proc addComponent*[T](scene: TScene, item: T) = 
  GetDefaultNode[T]().AddToNode(scene.id, item)

##gets the sequence of typ components in the given scene
template getComponent*(scene: TScene, typ: expr): expr = 
  GetDefaultNode[typ]().sceneList[scene.id]
##alias for getComponent

template components(scene: SceneId, typ: expr): expr = GetDefaultNode[typ]().sceneList[scene]
template components(scene: TScene, typ: expr): expr = components(scene.id, typ)
##functions to deal with adding systems to scenes, these
##are designed so that you can add a proc with the signature
##`proc(id: SceneId; comps: openarray[T])` or `proc(id: SceneId; x: T)` can be added to a
##scene.

##type class that matches everything that is not an openarray
type notArray = generic x
  not (x is openarray)
proc addSystem*[T](scene: var TScene, func: proc(id: SceneId, ts: openarray[T])) =
  scene.addSystem(proc(id: SceneId) {.closure.} =
    func(id, GetDefaultNode[T]().sceneList[id])
  )
proc addSystem*[T: notArray](scene: var TScene, func: proc(id: SceneId, t: T)) =
  scene.addSystem do (id: SceneId):
    for elm in components(id, T):
      func(id, elm)
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
  for elm in testScene.components(int):
    echo elm
  echo "testing SystemWrapper"
  addSystem(testScene, testSystem)
  addSystem(testScene, testIndividualSystem)
  testScene.update()
  
