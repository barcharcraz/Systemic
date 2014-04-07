import entity
import scene
import tables
import scenenode
import typetraits
type TEntPack = object
  # the componetns field stores a mapping
  # between typenames and integer offsets into
  # the datablock storeing this entities
  # components
  components: seq[tuple[typ: string, off: int]]
  datablock: pointer
  size: int

proc unpack*(pck: TEntPack, scene: var SceneId) =
  # we generate the entity id now because there is no
  # way to know which one we will have before we are
  # actually added to the scene
  var ent = genEntity()
  scene.add(ent)
  for elm in pck.components:
    var comp = cast[pointer](cast[int](pck.datablock) + elm.off)
    scene.addComponent(elm.typ, comp)
proc add*[T](pck: var TEntPack, item: var T) =
  ## adds an item to an entity package
  ## the item MUST be a plain object and contain
  ## no traced references, otherwise the behavior is 
  ## undefined. 

  # the size should always be just enough
  # to contain our elements
  # this means we can use it as our new offset
  var header = (typ: name(T), off: pck.size)
  realloc(pck.datablock, pck.size + sizeof(T))
  var dest = cast[pointer](cast[int](pck.datablock + header.off))
  moveMem(dest, cast[pointer](addr item), sizeof(T))
  pck.components.add(header)


