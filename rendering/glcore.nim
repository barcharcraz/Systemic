
import opengl
import components
import macros
import ecs.Scene
import ecs.entitynode
import ecs.scenenode
import ecs.entity
import logging
import exceptions
import vecmath
import unsigned
import math

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

type TShadowMap* = object
  depthTex*: GLuint
  shadowVP*: TMat4f
MakeEntityComponent(TShadowMap)

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
  glEnable(cGL_CULL_FACE)
  glFrontFace(GL_CCW)

proc GetCompileErrors*(shader: GLuint): string =
  var status: GLint
  var infoLogLen: GLsizei
  glGetShaderiv(shader, GL_COMPILE_STATUS.GLenum, addr status)
  if status == GL_FALSE:
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH.GLenum, addr infoLogLen)
    result = newString(infoLogLen)
    glGetShaderInfoLog(shader, infoLogLen, nil, result.cstring)
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
    logging.error(err)
  if GetIsCompiled(result) == false:
    raise newException(EGraphicsAPI, err)

proc CheckLinkStatus*(program: GLuint): tuple[status: GLint, err: string] =
  glGetProgramiv(program, GL_LINK_STATUS, addr result.status)
  if result.status == GL_FALSE:
    var errLen: GLint = 0
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, addr errLen)
    result.err = newString(errLen)
    glGetProgramInfoLog(program, errLen.GLsizei, nil, result.err.cstring)

proc CreateProgram*(shaders: varargs[GLuint]): GLuint =
  result = glCreateProgram()
  for elm in shaders:
    glAttachShader(result, elm)
  glBindAttribLocation(result, 0, "pos")
  glBindAttribLocation(result, 1, "uv")
  glBindAttribLocation(result, 2, "norm")
  glLinkProgram(result)
  var (res, err) = CheckLinkStatus(result)
  CheckError()
  if res == GL_FALSE:
    raise newException(EGraphicsAPI, err)
  for elm in shaders:
    glDetachShader(result, elm)
proc CreateVertexAttribPtr*(program, vbo, index: GLuint): GLuint =
  glGenVertexArrays(1, addr result)
  glBindVertexArray(result)
  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index)
  var posLoc = glGetAttribLocation(program, "pos")
  var uvLoc = glGetAttribLocation(program, "uv")
  var normLoc = glGetAttribLocation(program, "norm")
  if posLoc != -1:
    glEnableVertexAttribArray(posLoc.GLuint)
    glVertexAttribPointer(posLoc.GLuint, 3, cGL_FLOAT.GLenum, false, sizeof(TVertex).GLsizei, nil)
  if normLoc != -1:
    glEnableVertexAttribArray(normLoc.GLuint)
    glVertexAttribPointer(normLoc.GLuint, 3, cGL_FLOAT.GLenum, false, sizeof(TVertex).GLsizei, cast[pointer](sizeof(TVec3f)))
  if uvLoc != -1:
    glEnableVertexAttribArray(uvLoc.GLuint)
    glVertexAttribPointer(uvLoc.GLuint, 2, cGL_FLOAT.GLenum, false, sizeof(TVertex).GLsizei, cast[pointer]( 2 * sizeof(TVec3f)))
  glBindVertexArray(0)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

proc CreateMeshBuffers*(mesh: var TMesh): tuple[vert: GLuint, index: GLuint] =
  glGenBuffers(1, addr result.vert)
  glGenBuffers(1, addr result.index)
  glBindBuffer(GL_ARRAY_BUFFER, result.vert)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.index)
  var vertSize = sizeof(TVertex) * mesh.verts.len
  var indexSize = sizeof(uint32) * mesh.indices.len
  glBufferData(GL_ARRAY_BUFFER, vertSize.GLsizeiptr, addr mesh.verts[0], GL_STATIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexSize.GLsizeiptr, addr mesh.indices[0], GL_STATIC_DRAW)
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0)

proc BindModelMatrix*(program: GLuint; model: TMat4f) =
  var model = model
  var modelIdx = glGetUniformLocation(program, "mvp.model")
  if modelIdx == -1:
    warn("glGetUniformLocation returned -1 for modelidx")
  glUniformMatrix4fv(modelIdx, 1.GLsizei, false, cast[ptr GLfloat](addr model.data[0]))
proc BindViewProjMatrix*(program: GLuint, view, proj: TMat4f) =
  var proj = proj
  var view = view
  var viewIdx = glGetUniformLocation(program, "mvp.view")
  var projidx = glGetUniformLocation(program, "mvp.proj")
  CheckError()
  if projidx == -1:
    warn("glGetUniformLocation returned -1 for projIdx")
  if viewidx == -1:
    warn("glGetUniformLocation returned -1 for viewIdx")
  glUniformMatrix4fv(viewIdx, 1.GLsizei, false, cast[ptr GLfloat](addr view.data[0]))
  glUniformMatrix4fv(projidx, 1.GLsizei, false, cast[ptr GLfloat](addr proj.data[0]))

proc BindTransforms*(program: GLuint; model, view, proj: TMat4f) =
  BindViewProjMatrix(program, view, proj)
  BindModelMatrix(program, model)
proc BindMaterial*(program: GLuint; mat: var TMaterial) = 
  var ambiantIdx = glGetUniformLocation(program, "mat.ambiant")
  var diffuseIdx = glGetUniformLocation(program, "mat.diffuse")
  var specularIdx = glGetUniformLocation(program, "mat.specular")
  var shineIdx = glGetUniformLocation(program, "mat.shine")
  if ambiantIdx == -1: warn("glGetUniformLocation returned -1 for mat.ambiant")
  if diffuseIdx == -1: warn("glGetUniformLocation returned -1 for mat.diffuse")
  if specularIdx == -1: warn("glGetUniformLocation returned -1 for mat.specular")
  if shineIdx == -1: warn("glGetUniformLocation returned -1 for mat.shine")
  glUniform4fv(ambiantIdx, 1, addr mat.ambiant.data[0])
  glUniform4fv(diffuseIdx, 1, addr mat.diffuse.data[0])
  glUniform4fv(specularIdx, 1, addr mat.specular.data[0])
  glUniform1fv(shineIdx, 1, addr mat.shine)

proc InitializeTexture*(width,height: int; levels: int = 6): GLuint =
  var width = width
  var height = height
  glGenTextures(1, addr result)
  glBindTexture(GL_TEXTURE_2D, result)
  glTexParameteri(GL_TEXTURE_2D.GLenum, GL_TEXTURE_BASE_LEVEL.GLenum, 0)
  glTexParameteri(GL_TEXTURE_2D.GLenum, GL_TEXTURE_MAX_LEVEL.GLenum, (levels-1).GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR)
  for level in 0..levels-1:
    glTexImage2D(GL_TEXTURE_2D.GLenum, level.GLint, GL_RGBA8, width.GLsizei, height.GLsizei, 0, GL_RGBA, cGL_UNSIGNED_BYTE, nil)
    width = max(1, (width/2)).int
    height = max(1, (height/2)).int
  glBindTexture(GL_TEXTURE_2D, 0)
  #glTexStorage2D(GL_TEXTURE_2D, levels.GLsizei, GL_RGBA8, width.GLsizei, height.GLsizei)
proc CreateTexture*(data: pointer; width, height: int): GLuint =
  ## creates a texture using immutable texture storage and 
  ## uploads `data` to it.
  result = InitializeTexture(width, height)
  glBindTexture(GL_TEXTURE_2D, result)
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width.GLsizei, height.GLsizei, GL_BGRA, cGL_UNSIGNED_BYTE, data)
  glGenerateMipmap(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, 0)
proc AttachTextureToProgram*(texture: GLuint; program: GLuint; texUint: GLint; sampler: string) =
  glUseProgram(program)
  glActiveTexture(GL_TEXTURE0.GLuint + texUint.GLuint)
  glBindTexture(GL_TEXTURE_2D, texture)
  var samplerLoc = glGetUniformLocation(program, sampler.cstring)
  glUniform1i(samplerLoc, texUint)


proc InitializeDepthBuffer*(size: int): GLuint =
  assert(isPowerOfTwo(size))
  glGenTextures(1, addr result)
  glBindTexture(GL_TEXTURE_2D, result)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT_24, size.GLsizei, size.GLsizei, 0, GL_DEPTH_COMPONENT, GL_UNSIGNED_INT, nil)
  #glTexStorage2D(GL_TEXTURE_2D.GLenum, 1.GLsizei, GL_DEPTH_COMPONENT_24.GLenum, size.GLsizei, size.GLsizei)
  glTexParameteri(GL_TEXTURE_2D.GLenum, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D.GLenum, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glTexParameteri(GL_TEXTURE_2D.GLenum, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D.GLenum, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
  glTexParameteri(GL_TEXTURE_2D.GLenum, GL_TEXTURE_COMPARE_MODE, GL_COMPARE_REF_TO_TEXTURE)
  glTexParameteri(GL_TEXTURE_2D.GLenum, GL_TEXTURE_COMPARE_FUNC, GL_LEQUAL)
  glBindTexture(GL_TEXTURE_2D, 0)




proc CreateUniformBuffer*[T](arr: var openarray[T]): GLuint =
  glGenBuffers(1, addr result)
  glBindBuffer(GL_UNIFORM_BUFFER, result)
  glBufferData(GL_UNIFORM_BUFFER, (sizeof(T) * arr.len).GLsizeiptr, cast[pointer](addr arr), GL_STATIC_DRAW)
  glBindBuffer(GL_UNIFORM_BUFFER, 0)

proc UpdateUniformBuffer*[T](buffer: GLuint, arr: var openarray[T]) =
  var size: GLint
  glBindBuffer(GL_UNIFORM_BUFFER, buffer)
  glGetBufferParameteriv(GL_UNIFORM_BUFFER, GL_BUFFER_SIZE, addr size)
  if (arr.len * sizeof(T)) > size:
    glBufferData(GL_UNIFORM_BUFFER, (sizeof(T) * arr.len).GLsizeiptr, cast[pointer](addr arr), GL_STATIC_DRAW)
  else:
    glBufferSubData(GL_UNIFORM_BUFFER, 0.GLintPtr, (sizeof(T) * arr.len).GLsizeiptr, cast[pointer](addr arr))
  glBindBuffer(GL_UNIFORM_BUFFER, 0)



 
