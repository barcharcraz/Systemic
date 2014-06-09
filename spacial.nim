import components
import ecs
import vecmath
import tables
type TOctreeNodeKind = enum
  onkLeaf,
  onkInternal
type TOctreeNode*[T] = object
  case kind: TOctreeNodeKind
  of onkLeaf: items*: seq[T]
  of onkInternal: children*: array[1..8, ref TOctreeNode[T]]


type TBVHNode*[T] = object
  aabb: TAlignedBox3f
  items: seq[T]
  children: seq[TBVHNode[T]]
proc initOctreeNode*[T](kind: TOctreeNodeKind): TOctreeNode =
  result.kind = kind
  case kind
  of onkLeaf: result.items = @[]
  else: discard

const BVHMinItems = 3
proc MakeBVHArray(aabbs: array[1..8, TAlignedBox3f): array[1..8, TAlignedBox3f] =
  for i in 1..8:
    result[i].aabb = aabbs[i]
    result[i].items = @[]
proc ConstructBVHHelper(scene: SceneId; parent: var TBVHNode[EntityId]): TBVHNode[EntityId] =
  var nextItr = next(scene, TAxisAlignedBB)
  if parent.items.len <= BVHMinItems:
    var center = parent.aabb.centroid()
    parent.aabb = TAlignedBox3f(min: center, max: center)
    for elm in parent.items:
      var aabb = nextItr(elm)
      parent.aabb.incl(aabb[].CurAABB)

  parent.children.add(MakeBVHArray(split(parent.aabb)))
  for id in parent.items:
    var center = nextItr(id)[].CurAABB.centroid()
    for child in parent.children:
      if center in child.aabb:
        child.items.add(id)
        break
  parent.items = nil

proc ConstructBVH(scene: SceneId): TBVHNode[EntityId] =
  result.items = @[]
  result.children = @[]
  # compute the bounding box for the root node
  for id, aabb in walk(scene, TAxisAlignedBB):
    result.aabb.extend(aabb[].CurAABB)
    result.items.add(id)
  


