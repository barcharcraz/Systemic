import Scene
import macros
type TSceneNode*[T] = object
  sceneList: seq[seq[T]]
proc initSceneNode[T](): TSceneNode[T] = 
  result.sceneList = newSeq[seq[T]]()

proc addToNode[T](node: TSceneNode[T], scene: SceneId, item: T) =
  if node.sceneList.len <= scene:
    node.sceneList.insert(newSeq[T](), scene)
  node.sceneList[scene].add(item)


macro GetDefaultNodeName(typ: expr): expr {.immediate.} = 
  result = newIdentNode($typ & "SceneNode")

macro MakeComponentNode(typ: expr): stmt =
  var nodeName = repr(typ) & "SceneNode"
  var brackets = newNimNode(nnkBracketExpr)
  brackets.add(newIdentNode(!"TSceneNode"))
  brackets.add(newIdentNode(!(repr(typ))))
  var identDefs = newNimNode(nnkIdentDefs)
  identDefs.add(newIdentNode(nodeName))
  identDefs.add(brackets)
  identDefs.add(newNimNode(nnkEmpty))
  result = newNimNode(nnkStmtList)
  result.add(newNimNode(nnkVarSection).add(identDefs))


template MakeComponent(typ: typedesc) {.immediate.} =
  MakeComponentNode(typ)
  GetDefaultNodeName(typ) = initSceneNode[typ]()

proc addComponent[T](scene: TScene, item: T) = 
  GetDefaultNodeName(T).AddToNode(scene.id, item)

when isMainModule:
  MakeComponent(int)
  echo intSceneNode.sceneList.len
