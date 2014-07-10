import vecmath
import math
import unsigned
import algorithm
import sequtils
import colors
import ecs
type TPrimMesh* = object
  verts*: seq[TVec3f]
  indices*: seq[uint32]
type TPrim* = object
  pos*: TVec3f
  color*: TVec3f
  mesh*: TPrimMesh
MakeEntityComponent(TPrim)
proc PrimCircleMesh(radius: float): TPrimMesh =
  const steps = 8
  var nextVert = vec3f(radius,0,0)
  var rotation = quatFromAngleAxis((2*PI)/steps, vec3f(0,1,0))
  result.verts = @[]
  result.indices = @[]
  result.verts.add(vec3f(0,0,0))
  result.indices.add(0)
  for i in 1..steps:
    nextVert = mulv(rotation, nextVert)
    result.verts.add(nextVert)
    result.indices.add(result.verts.high.uint32)
    result.indices.add(result.verts.high.uint32-1)
    result.indices.add(0)
  result.indices.add(1)
  result.indices.add(result.verts.high.uint32)

proc PrimConeMesh*(radius: float, height: float): TPrimMesh =
  const steps = 8
  result = PrimCircleMesh(radius)
  result.verts.add(vec3f(0,height,0))
  var topIdx = result.verts.high
  for i in 1..steps:
    result.indices.add(uint32(i))
    result.indices.add(uint32(i+1))
    result.indices.add(topIdx.uint32)
  result.indices.add(result.verts.high.uint32 - 1)
  result.indices.add(1)
  result.indices.add(topIdx.uint32)
proc PrimCylinderMesh*(radius: float, height: float): TPrimMesh =
  result = PrimCircleMesh(radius)
  for i,elm in result.verts.pairs():
    result.verts[i][2] = result.verts[i][2] - height/2
  var topCircle = PrimCircleMesh(radius)
  topCircle.indices.reverse()
  for i,elm in topCircle.verts.pairs():
    topCircle.verts[i][2] = topCircle.verts[i][2] + height/2
  for i,elm in topCircle.indices.pairs():
    topCircle.indices[i] = topCircle.indices[i] + topCircle.verts.len.uint32
  #original length of the first circle, so we can iterate
  #and add the sides
  var circleLen = result.verts.len.uint32
  result.verts = concat(result.verts, topCircle.verts)
  result.indices = concat(result.indices, topCircle.indices)
  for i in 1..circleLen - 2:
    result.indices.add(uint32(i+1))
    result.indices.add(uint32(i + circleLen))
    result.indices.add(uint32(i))
    result.indices.add(uint32(i + circleLen))
    result.indices.add(uint32(i+1))
    result.indices.add(uint32(i + circleLen + 1))
  result.indices.add(1)
  result.indices.add(circleLen + 1)
  result.indices.add(circleLen - 1)
  result.indices.add(circleLen + 1)
  result.indices.add(uint32(result.verts.high))
  result.indices.add(circleLen - 1)

proc PrimBoundingBoxMesh(aabb: TAlignedBox3f): TPrimMesh =
  result.verts = @[]
  result.indices = @[]
  for elm in TCornerType:
    var corner = aabb.corner(elm)
    result.verts.add(corner)
  result.indices = @[
    0.uint32,5,4,
    1,5,0,
    0,2,1,
    1,2,3,
    1,7,5,
    3,7,1,
    3,6,7,
    2,6,3,
    0,6,2,
    4,6,0,
    5,6,4,
    7,6,5
  ]

proc initPrim(mesh: TPrimMesh, color: TColor, pos: TVec3f): TPrim =
  result.mesh = mesh
  var (r,g,b) = extractRGB(color)
  result.color = vec3f(float(r),float(g),float(b)).normalize()
  result.pos = pos

proc PrimCone*(pos: TVec3f = vec3f(0,0,0),
               color: TColor = colForestGreen,
               radius: float = 10.0,
               height: float = 10.0): TPrim =
  result = initPrim(PrimConeMesh(radius, height), color, pos)

proc PrimCylinder*(pos: TVec3f = vec3f(0,0,0),
                   color: TColor = colBlue,
                   radius: float = 10.0,
                   height: float = 10.0): TPrim =
  result = initPrim(PrimCylinderMesh(radius, height), color, pos)

proc PrimHandle*(pos: TVec3f = vec3f(0,0,0), 
                 scale: float = 1.0): seq[TPrim] =
  let height = 4.0 * scale
  # we translate before we rotate, so we only need
  # the translation in the 'y' axis
  let transl = vec3f(0,height/2,0)
  var xcyl = PrimCylinder(pos, colRed, 1.0 * scale, height)
  var ycyl = PrimCylinder(pos, colGreen, 1.0 * scale, height)
  var zcyl = PrimCylinder(pos, colBlue, 1.0 * scale, height)
  let xrot = quatFromAngleAxis(PI/2, vec3f(0,0,1))
  let yrot = identityQuatf()
  let zrot = quatFromAngleAxis(PI/2, vec3f(1,0,0))
  proc moveCyl(rot: TQuatf, cyl: var TPrimMesh) =
    for i,v in cyl.verts:
      cyl.verts[i] = v + transl
      cyl.verts[i] = mulv(rot, v)
  moveCyl(xrot, xcyl.mesh)
  moveCyl(yrot, ycyl.mesh)
  moveCyl(zrot, zcyl.mesh)
  result = @[xcyl, ycyl, zcyl]
 

proc PrimBoundingBox*(aabb: TAlignedBox3f): TPrim =
  result = initPrim(PrimBoundingBoxMesh(aabb), colGreen, vec3f(0,0,0))
