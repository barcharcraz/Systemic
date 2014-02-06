import Scene
import macros
type TSceneNode*[T] = object
  sceneList: seq[seq[T]]

template MakeComponent(typ: expr) {.immediate.} =
  var `typ SceneNode`: TSceneNode[typ]
  #echo repr(`typ SceneNode`)
  #proc addComponent*(scene: TScene, comp: typ) = 
  #  node.sceneList[scene.id].add(comp)

when isMainModule:
  MakeComponent(int)
  #echo intSceneNode.sceneList.len
