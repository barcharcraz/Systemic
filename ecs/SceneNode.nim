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


macro GetDefaultNodeName(typ: string): expr = 
  result = newIdentNode(!($typ & "SceneNode"))
  #echo result

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
  GetDefaultNodeName((T.name)).AddToNode(scene.id, item)
template getComponent*(scene: TScene, typ: expr): expr = 
  GetDefaultNodeName(typ.name).sceneList[scene.id]
template components(scene: TScene, typ: expr): expr = getComponent(scene,typ)
when isMainModule:
  MakeComponent(int)
  echo intSceneNode.sceneList.len
  var testScene = initScene()
  testScene.addComponent(4)
  testScene.addComponent(5)
  for elm in testScene.components(int):
    echo elm
