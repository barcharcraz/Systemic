import components
import ecs
import vecmath
import tables
type TOctreeNodeKind = enum
  onkLeaf,
  onkInternal
type TOctreeNode*[T] = object
  area*: TAlignedBox3f
  case kind: TOctreeNodeKind
  of onkLeaf: items*: seq[T]
  of onkInternal: children*: array[1..8, ref TOctreeNode[T]]

const OctreeMinItems = 4

proc initOctreeNode*[T](kind: TOctreeNodeKind): TOctreeNode =
  result.kind = kind
  case kind
  of onkLeaf: result.items = @[]
  else: discard

type TOctreeItem = tuple[id: EntityId, aabb: TAxisAlignedBB]
proc MakeOctreeNode(itms: seq[TOctreeItem], bbox: TAlignedBox3f): ref TOctreeNode[EntityId] =
  new(result)
  result.area = bbox
  if itms.len <= OctreeMinItems:
    result = initOctreeNode[EntityId](onkLeaf)
    #add all the items
    for elm in itms:
      assert(elm.aabb in result.area)
      result.items.add(elm.id)
  else:
    result = initOctreeNode[EntityId](onkInternal)
    var splits = split(result.area)
    for i in 1..8:
      var childItems: seq[TOctreeItem] = @[]
      for elm in itms:
        if elm.aabb in splits[i]:
          childItems.add(elm)
      result.children[i] = MakeOctreeNode(childItems, splits[i])
    
proc MakeOctree(scene: SceneId): ref TOctreeNode[EntityId] =
  var allItems: seq[TOctreeItem] = @[]
  for id, aabb in walk(scene, TAxisAlignedBB)
    allItems.add((id: id, aabb: aabb[].CurAABB))
  var bbox = allItems[0].aabb
  for elm in allItems:
    bbox.extend(elm.aabb)
  result = MakeOctreeNode(allItems, bbox)
  
