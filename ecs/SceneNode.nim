import Scene
import macros
type TSceneNode*[T] = object
  sceneList: seq[seq[T]]

macro MakeComponent(typ: expr): expr =
  var brackets = newNimNode(nnkBracketExpr)
  brackets.add(newIdentNode(!"TSceneNode"))
  brackets.add(newIdentNode(!($typ)))
  var identDefs = newNimNode(nnkIdentDefs)
  identDefs.add(newIdentNode($typ & "SceneNode"))
  identDefs.add(brackets)
  identDefs.add(newNimNode(nnkEmpty))
  result = newNimNode(nnkVarSection).add(identDefs)

when isMainModule:
  MakeComponent(int)
  echo intSceneNode.sceneList.len
