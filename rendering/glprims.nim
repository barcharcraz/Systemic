##implements opengl rendering for some primitive shapes that
##are deemed useful, great for dubuggging and maybe for editors
##not ideal for real games since speed is not a priority
##(batching will not happen, draw calls will contain a handful of elms, etc)

import glcore
import opengl
import prims
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




proc DrawPrimCone*(pos: TVec3f = vec3f(0,0,0),
               color: TColor = colForestGreen,
               radius: float = 10.0,
               height: float = 10.0) =
  PrimitiveStack.add(PrimCone(pos, color, radius, height))
proc DrawPrimCylinder*(pos: TVec3f = vec3f(0,0,0),
                   color: TColor = colBlue,
                   radius: float = 10.0,
                   height: float = 10.0) =
  PrimitiveStack.add(PrimCylinder(pos, color, radius, height))
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
  for elm in components(scene, TPrim):
    echo repr(elm)
    RenderPrim(elm, view, projMatrix)
