
import opengl
import components
import ecs.Scene
import ecs.entitynode
import ecs.scenenode
import ecs.entity
import logging
import exceptions
import vecmath
import unsigned
type THasDrawn* = distinct bool
MakeComponent(THasDrawn)
## structure that holds per-object
## OpenGL information
type TObjectBuffers* = object
  vertex*: GLuint
  index*: GLuint
  vao*: GLuint
  tex*: GLuint
proc initObjectBuffers*(): TObjectBuffers =
  result.vertex = 0
  result.index = 0
  result.vao = 0
MakeEntityComponent(TObjectBuffers)
##some utility functions
proc EnumString*(val: GLenum): string =
  ## gets the string representation of
  ## `val`
  case val
  of GL_INVALID_ENUM: result = "GL_INVALID_ENUM"
  of GL_INVALID_OPERATION: result = "GL_INVALID_OPERATION"
  of GL_INVALID_VALUE: result = "GL_INVALID_VALUE"
  else: result = "unrecognised enum"
proc CheckError*() =
  ##checks for an openGL error and throws an exception if there
  ##is one
  var err = glGetError()
  if err != GL_NO_ERROR:
    var errStr = EnumString(err)
    raise newException(EGraphicsAPI, errStr)
proc initOpenGlRenderer*() =
  loadExtensions()
  glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LEQUAL)
  glDepthMask(true)
  glDepthRange(0.0'f32, 1.0'f32)
  #glEnable(cGL_CULL_FACE)
  #glFrontFace(GL_CW)

proc GetCompileErrors*(shader: GLuint): string =
  var status: GLint
  var infoLogLen: GLsizei
  glGetShaderiv(shader, GL_COMPILE_STATUS.GLenum, addr status)
  if status == GL_FALSE:
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH.GLenum, addr infoLogLen)
    result = newString(infoLogLen)
    glGetShaderInfoLog(shader, infoLogLen, cast[var GLint](nil), result.cstring)
  else:
    result = ""

proc GetIsCompiled*(shader: GLuint): bool =
  var rv: GLint = 0
  glGetShaderiv(shader, GL_COMPILE_STATUS.GLenum, addr rv)
  result = (rv != 0)

proc CompileShader*(stype: GLenum; source: string): GLuint =
  result = glCreateShader(stype)
  var csource: cstring = source.cstring
  glShaderSource(result, 1.GLsizei, cast[cstringArray](addr csource), nil)
  glCompileShader(result)
  var err = GetCompileErrors(result)
  if err != "":
    error(err)
  if GetIsCompiled(result) == false:
    raise newException(EGraphicsAPI, err)

proc CheckLinkStatus*(program: GLuint): tuple[status: GLint, err: string] =
  glGetProgramiv(program, GL_LINK_STATUS, addr result.status)
  if result.status == GL_FALSE:
    var errLen: GLint = 0
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, addr errLen)
    result.err = newString(errLen)
    glGetProgramInfoLog(program, errLen.GLsizei, cast[var GLint](nil), result.err.cstring)

proc CreateProgram*(shaders: varargs[GLuint]): GLuint =
  result = glCreateProgram()
  for elm in shaders:
    glAttachShader(result, elm)
  glLinkProgram(result)
  var (res, err) = CheckLinkStatus(result)
  CheckError()
  if res == GL_FALSE:
    raise newException(EGraphicsAPI, err)
  for elm in shaders:
    glDetachShader(result, elm)
  CheckError()

proc CreateTVertexAttribPtr*(program: GLuint): GLuint =
  glGenVertexArrays(1, addr result)
  glBindVertexArray(result)
  var posLoc = glGetAttribLocation(program, "pos")
  var uvLoc = glGetAttribLocation(program, "uv")
  var normLoc = glGetAttribLocation(program, "norm")
  if posLoc != -1:
    glEnableVertexAttribArray(posLoc.GLuint)
    glVertexAttribPointer(posLoc.GLuint, 3, cGL_FLOAT.GLenum, false, sizeof(TVertex).GLsizei, nil)
  if normLoc != -1:
    glEnableVertexAttribArray(normLoc.GLuint)
    glVertexAttribPointer(normLoc.GLuint, 3, cGL_FLOAT.GLenum, false, sizeof(TVertex).GLsizei, cast[ptr GLvoid](sizeof(TVec3f)))
  if uvLoc != -1:
    glEnableVertexAttribArray(uvLoc.GLuint)
    glVertexAttribPointer(uvLoc.GLuint, 2, cGL_FLOAT.GLenum, false, sizeof(TVertex).GLsizei, cast[ptr GLvoid]( 2 * sizeof(TVec3f)))

proc CreateMeshBuffers*(mesh: var TMesh): tuple[vert: GLuint, index: GLuint] =
  glGenBuffers(1, addr result.vert)
  glGenBuffers(1, addr result.index)
  glBindBuffer(GL_ARRAY_BUFFER, result.vert)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.index)
  var vertSize = sizeof(TVertex) * mesh.verts.len
  var indexSize = sizeof(uint32) * mesh.indices.len
  glBufferData(GL_ARRAY_BUFFER, vertSize.GLsizeiptr, addr mesh.verts[0], GL_STATIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, vertSize.GLsizeiptr, addr mesh.indices[0], GL_STATIC_DRAW)
  

proc BindTransforms*(program: GLuint; model, view, proj: var TMat4f) =
  var viewIdx = glGetUniformLocation(program, "mvp.view")
  var modelIdx = glGetUniformLocation(program, "mvp.model")
  var projidx = glGetUniformLocation(program, "mvp.proj")
  CheckError()
  if projidx == -1:
    warn("glGetUniformLocation returned -1 for projIdx")
  if viewidx == -1:
    warn("glGetUniformLocation returned -1 for viewIdx")
  if modelidx == -1:
    warn("glGetUniformLocation returned -1 for modelIdx")
  glUniformMatrix4fv(viewIdx, 1.GLsizei, false, cast[PGLfloat](addr view[0]))
  glUniformMatrix4fv(projidx, 1.GLsizei, false, cast[PGLfloat](addr proj[0]))
  glUniformMatrix4fv(modelidx, 1.GLsizei, false, cast[PGLfloat](addr model[0]))
  CheckError()

proc CreateTexture*(data: GLvoid; width, height: int): GLuint =
  ## creates a texture using immutable texture storage and 
  ## uploads `data` to it.
  glGenTextures(1, addr result)
  glBindTexture(GL_TEXTURE_2D, result)
  glTexStorage2D(GL_TEXTURE_2D, 6, GL_RGBA8, width.GLsizei, height.GLsizei)
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width.GLsizei, height.GLsizei, GL_BGRA, cGL_UNSIGNED_BYTE, data)
  glGenerateMipmap(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, 0)
proc AttachTextureToProgram*(texture: GLuint; program: GLuint; texUint: GLint; sampler: string) =
  glUseProgram(program)
  glActiveTexture(GL_TEXTURE0.GLuint + texUint.GLuint)
  glBindTexture(GL_TEXTURE_2D, texture)
  var samplerLoc = glGetUniformLocation(program, sampler.cstring)
  glUniform1i(samplerLoc, texUint)


