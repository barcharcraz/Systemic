import entity
import scene
import tables
import scenenode
type TEntPack = object
  # the componetns field stores a mapping
  # between typenames and integer offsets into
  # the datablock storeing this entities
  # components
  components: seq[tuple[typ: string, off: int]]
  datablock: pointer
  size: int

proc unpack*(pck: TEntPack, scene: var SceneId) =
  for elm in pck.components:
    var comp = cast[pointer](cast[int](pck.datablock) + elm.off)
    scene.addComponent(elm.typ, comp)

