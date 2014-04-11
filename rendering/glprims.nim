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
  gl_position = mvp.proj * mvp.view * mvp.model * pos;
}
"""
const primPS = """
#version 140
uniform vec3 color;
out vec4 outputColor;
void main() {
  outputColor = color;
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
  if vs == 0: vs = CompileShader(GL_VERTEX_SHADER, primVS)
  if ps == 0: ps = CompileShader(GL_FRAGMENT_SHADER, primPS)
  if prog == 0: prog = CreateProgram(vs, ps)
  result = prog

var PrimitiveStack: seq[TPrim]
proc ConePrim*(radius: float, height: float): TPrimMesh =
  const steps = 8
  var nextVert = vec3f(1,0,0)
  var rotation = quatFromAngleAxis((2*PI)/steps, vec3f(0,0,1))
  result.verts.add(vec3f(0,0,0))
  for i in 1..8:
    nextVert = mulv(rotation, nextVert)
    result.verts.add(nextVert)
    result.indices.add(result.verts.high)
    if i mod 2 == 0:
      result.indicies.add(0)
proc initPrim(mesh: TPrimMesh, color: TColor, pos: TVec3f): TPrim =
  result.mesh = mesh
  result.color = color
  result.pos = pos
proc RenderPrim*(elm: TPrim, view,proj: TMat4f) =
  var vbo {.global.}: GLuint
  var index {..global.}: GLuint
  var vao {.global.}: GLuint
  glUseProgram(getPrimProgram())
  BindTransforms(program, elm.pos, view, proj)
  var colorIdx = glGetUniformLocation(getPrimProgram(), "color")
  glUniform3fv(colorIdx, 1, addr elm.color)
  if vbo == 0: glGenBuffers(1, addr vbo)
  if index == 0: glGenBuffers(1, addr index)
  var vertSize = sizeof(TVec3f) * elm.mesh.verts.len
  var indexSize = sizeof(uint32) * elm.mesh.indices.len
  glBufferData(GL_ARRAY_BUFFER, vertSize.GLsizeiptr, addr elm.mesh.verts[0], GL_DYNAMIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexSize.GLsizeiptr, addr elm.mesh.indices[0], GL_DYNAMIC_DRAW)
  
  if vao == 0: glGenVertexArrays(1, addr vao)
  glBindVertexArray(vao)
  var posLoc = glGetAttribLocation(program, "pos")
  if posLoc == -1: raise newException(EVertexAttributeNotFound, "pos not found")
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(posLoc, 3, cGL_FLOAT, false, sizeof(TVec3f).GLsizei, nil)
  glBindBuffer(GL_ARRAY_BUFFER.GLenum, vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index)
  glDrawElements(GL_TRIANGLES, cast[GLSizei](elm.mesh.indices.len), cGL_UNSIGNED_INT, nil)
proc PrimitiveRenderSystem(scene: SceneId) {.procvar.} =
  var cament = matchEnt(scene, TCamera, TTransform)
  var camTrans = EntFirst[TTransform](cament)
  var camera = EntFirst[TCamera](cameraEnt)
  var view = camTrans.GenMatrix()
  var projMatrix = cam
  for elm in PrimitiveStack:
    RenderPrim(elm, view, proj)
  PrimitiveStack.setLen(0)
