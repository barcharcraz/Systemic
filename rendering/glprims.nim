##implements opengl rendering for some primitive shapes that
##are deemed useful, great for dubuggging and maybe for editors
##not ideal for real games since speed is not a priority
##(batching will not happen, draw calls will contain a handful of elms, etc)

import glcore
import opengl
import vecmath
import math
import colors
import exceptions
import components
import ecs
import unsigned
import algorithm
import sequtils
const primVS = """
#version 140
struct matrices_t {
  mat4 model;
  mat4 view;
  mat4 proj;
};

uniform matrices_t mvp;
in vec3 pos;
void main() {
  gl_Position = mvp.proj * mvp.view * mvp.model * vec4(pos, 1);
}
"""
const primPS = """
#version 140
uniform vec3 color;
out vec4 outputColor;
void main() {
  outputColor = vec4(color,1);
}
"""
type TPrimMesh = object
  verts: seq[TVec3f]
  indices: seq[uint32]
type TPrim = object
  pos: TVec3f
  color: TVec3f
  mesh: TPrimMesh
type TPrimType* = enum
  ptCone
proc getPrimProgram(): GLuint =
  var prog {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  if vs.int == 0: vs = CompileShader(GL_VERTEX_SHADER, primVS)
  if ps.int == 0: ps = CompileShader(GL_FRAGMENT_SHADER, primPS)
  if prog.int == 0: prog = CreateProgram(vs, ps)
  result = prog

var PrimitiveStack: seq[TPrim] = @[]
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
  const steps = 8
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

proc initPrim(mesh: TPrimMesh, color: TColor, pos: TVec3f): TPrim =
  result.mesh = mesh
  var (r,g,b) = extractRGB(color)
  result.color = vec3f(float(r),float(g),float(b)).normalized()
  result.pos = pos

proc PrimCone*(pos: TVec3f = vec3f(0,0,0),
               color: TColor = colForestGreen,
               radius: float = 10.0,
               height: float = 10.0) =
  PrimitiveStack.add(initPrim(PrimConeMesh(radius, height), color, pos))
proc PrimCylinder*(pos: TVec3f = vec3f(0,0,0),
                   color: TColor = colBlue,
                   radius: float = 10.0,
                   height: float = 10.0) =
  PrimitiveStack.add(initPrim(PrimCylinderMesh(radius, height), color, pos))
proc RenderPrim*(elm: TPrim, view,proj: TMat4f) =
  var elm = elm
  var vbo {.global.}: GLuint
  var index {.global.}: GLuint
  var vao {.global.}: GLuint
  glUseProgram(getPrimProgram())
  BindTransforms(getPrimProgram(), elm.pos.toTranslationMatrix(), view, proj)
  var colorIdx = glGetUniformLocation(getPrimProgram(), "color")
  glUniform3fv(colorIdx, 1, cast[PGLfloat](addr elm.color.data))
  if vbo == 0: glGenBuffers(1, addr vbo)
  if index == 0: glGenBuffers(1, addr index)
  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index)
  var vertSize = sizeof(TVec3f) * elm.mesh.verts.len
  var indexSize = sizeof(uint32) * elm.mesh.indices.len
  glBufferData(GL_ARRAY_BUFFER, vertSize.GLsizeiptr, addr elm.mesh.verts[0], GL_DYNAMIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexSize.GLsizeiptr, addr elm.mesh.indices[0], GL_DYNAMIC_DRAW)
  
  if vao == 0: glGenVertexArrays(1, addr vao)
  glBindVertexArray(vao)
  var posLoc = glGetAttribLocation(getPrimProgram(), "pos")
  if posLoc == -1: raise newException(EVertexAttributeNotFound, "pos not found")
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(posLoc.GLuint, 3, cGL_FLOAT, false, sizeof(TVec3f).GLsizei, cast[PGLvoid](nil))
  glBindBuffer(GL_ARRAY_BUFFER.GLenum, vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index)
  glDrawElements(GL_TRIANGLES, cast[GLSizei](elm.mesh.indices.len), cGL_UNSIGNED_INT, nil)
  CheckError()
proc PrimitiveRenderSystem*(scene: SceneId) {.procvar.} =
  var cament = matchEnt(scene, TCamera, TTransform)
  var camTrans = EntFirst[TTransform](cament)
  var camera = EntFirst[TCamera](cament)
  var view = camTrans.GenRotTransMatrix().AdjustViewMatrix()
  var projMatrix = camera.AdjustProjMatrix()
  for elm in PrimitiveStack:
    RenderPrim(elm, view, projMatrix)
  PrimitiveStack.setLen(0)
