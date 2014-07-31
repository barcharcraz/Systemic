##implements opengl rendering for some primitive shapes that
##are deemed useful, great for dubuggging and maybe for editors
##not ideal for real games since speed is not a priority
##(batching will not happen, draw calls will contain a handful of elms, etc)

import glcore
import glshaders
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
import utils/iterators
import genutils


type TPrimType* = enum
  ptCone
proc getPrimProgram(): GLuint =
  var prog {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  if vs.int == 0: vs = CompileShader(GL_VERTEX_SHADER, BasicVS)
  if ps.int == 0: ps = CompileShader(GL_FRAGMENT_SHADER, BasicPS)
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
  glUniform3fv(colorIdx, 1, cast[ptr GLfloat](addr elm.color.data))
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
  glVertexAttribPointer(posLoc.GLuint, 3, cGL_FLOAT, false, sizeof(TVec3f).GLsizei, cast[pointer](nil))
  glBindBuffer(GL_ARRAY_BUFFER.GLenum, vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index)
  glDrawElements(GL_TRIANGLES, cast[GLSizei](elm.mesh.indices.len), GL_UNSIGNED_INT, nil)
  CheckError()
  
proc PrimitiveRenderSystem*(scene: SceneId) {.procvar.} =
  var cament = first(walk(scene, TCamera, TTransform))[0]
  var camTrans = cament@TTransform
  var camera = (cament@TCamera).matrix
  var view = camTrans.GenRotTransMatrix().AdjustViewMatrix()
  var projMatrix = camera.AdjustProjMatrix()
  glDisable(cGL_CULL_FACE)
  glPolygonMode(GL_FRONT_AND_BACK, GL_LINE)
  for elm in PrimitiveStack:
    RenderPrim(elm, view, projMatrix)
  PrimitiveStack.setLen(0)
  for elm in components(scene, TPrim):
    RenderPrim(elm, view, projMatrix)
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
  glEnable(cGL_CULL_FACE)
