import components
import ecs
import vecmath
import tables
import exceptions
type TOctreeNodeKind = enum
  onkLeaf,
  onkInternal

type TOctreeItem[T] = tuple[id: T, aabb: TAlignedBox3f]
type TOctreeNode*[T] = object
  area: TAlignedBox3f
  case kind: TOctreeNodeKind
  of onkLeaf: items*: seq[TOctreeItem[T]]
  of onkInternal: children*: array[1..8, ref TOctreeNode[T]]

const OctreeMinItems = 2

proc `==`[T](a: TOctreeItem[T], b: T): bool = a.id == b

proc initOctreeNode*[T](kind: TOctreeNodeKind): TOctreeNode[T] =
  result.kind = kind
  case kind
  of onkLeaf: result.items = @[]
  else: discard

proc MakeOctreeNode[T](itms: seq[TOctreeItem[T]], bbox: TAlignedBox3f): ref TOctreeNode[T] =
  new(result)
  result.area = bbox
  if itms.len <= OctreeMinItems:
    result[] = initOctreeNode[EntityId](onkLeaf)
    #add all the items
    for elm in itms:
      assert(elm.aabb in result.area)
      result.items.add(elm)
  else:
    result[] = initOctreeNode[EntityId](onkInternal)
    var splits = split(result.area)
    for i in 1..8:
      var childItems: seq[TOctreeItem[T]] = @[]
      for elm in itms:
        if elm.aabb in splits[i]:
          childItems.add(elm)
      result.children[i] = MakeOctreeNode(childItems, splits[i])
    
proc MakeOctree*(scene: SceneId): ref TOctreeNode[EntityId] =
  var allItems: seq[TOctreeItem[EntityId]] = @[]
  for id, aabb in walk(scene, TAxisAlignedBB):
    allItems.add((id: id, aabb: aabb[].CurAABB))
  if allItems.len == 0: return nil
  var bbox = allItems[0].aabb
  for elm in allItems:
    bbox.extend(elm.aabb)
  result = MakeOctreeNode(allItems, bbox)


proc add*[T](octree: var TOctreeNode[T], item: T, location: TAlignedBox3f) =
  if octree.kind == onkLeaf:
    assert(location in octree.area)
    octree.items.add((item, location))
    if octree.items.len >= OctreeMinItems:
      octree = MakeOctreeNode(octree.items, octree.area)[]
  else:
    for elm in octree.children:
      if location in elm.area:
        add(elm[], item, location)
proc add*(octree: var TOctreeNode[EntityId], item: EntityId) =
  var aabb = item@TAxisAlignedBB
  add(octree, item, aabb.CurAABB)

proc del*[T](octree: var TOctreeNode[T], item: T, location: TAlignedBox3f) =
  if octree.kind == onkLeaf:
    assert(location in octree.area)
    var idx = find(octree.items, item)
    if idx == -1:
      raise newException(ENotFound, "Entity not found in octree")
    del(octree.items, idx)
  else:
    for elm in octree.children:
      if location in elm.area:
        del(elm[], item, location)

proc del*(octree: var TOctreeNode[EntityId], item: EntityId) =
  var aabb = item@TAxisAlignedBB
  del(octree, item, aabb.CurAABB)

proc move*[T](octree: var TOctreeNode[T], item: T, oldLoc, newLoc: TAlignedBox3f) =
  ## update the bounding box of an object in the octree
  ## we simply delete the object and re-insert it,
  ## there are more creative ways to go about it but they are
  ## not all that useful since we do not have parent links in the tree
  ## and I do not want to add them unless it shows on profiles
  del(octree, item, oldLoc)
  add(octree, item, newLoc)

proc query*[T](octree: TOctreeNode[T], location: TAlignedBox3f): seq[T] =
  result = @[]
  if octree.kind == onkLeaf:
    assert(location in octree.area)
    for elm in octree.items:
      if elm.aabb in location:
        result.add(elm)
  else:
    for elm in octree.children:
      if location in elm[].area:
        result.add(query(elm[], location))

proc GetBoundingBoxxes*(octree: TOctreeNode): seq[TAlignedBox3f] =
  result = @[]
  result.add(octree.area)
  if octree.kind == onkInternal:
    for elm in octree.children:
      result.add(GetBoundingBoxxes(elm[]))
