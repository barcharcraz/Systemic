import opengl
import components.mesh
import components.camera
import components.transform
import components.image
import components
import ecs.Scene
import ecs.entitynode
import ecs.entity
import ecs.scenenode
import logging
import exceptions
import vecmath
import unsigned
## structure that holds per-object
## OpenGL information
type TObjectBuffers = object
  vertex: GLuint
  index: GLuint
  vao: GLuint
  tex: GLuint
proc initObjectBuffers(): TObjectBuffers =
  result.vertex = 0
  result.index = 0
  result.vao = 0
MakeEntityComponent(TObjectBuffers)
##some utility functions
proc EnumString(val: GLenum): string =
  ## gets the string representation of
  ## `val`
  case val
  of GL_INVALID_ENUM: result = "GL_INVALID_ENUM"
  of GL_INVALID_OPERATION: result = "GL_INVALID_OPERATION"
  of GL_INVALID_VALUE: result = "GL_INVALID_VALUE"
  else: result = "unrecognised enum"
proc CheckError() =
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



var defVS = """
#version 140
struct matrices_t {
  mat4 model;
  mat4 view;
  mat4 proj;
};
uniform matrices_t mvp;

in vec3 pos;
in vec3 norm;
in vec2 uv;
out vec3 norm_out;
out vec2 uv_out;
void main() {
  mat4 modelviewproj = mvp.proj * mvp.view * mvp.model;
  mat4 modelview = mvp.view * mvp.model;
  norm_out = norm;
  uv_out = uv;
  vec4 rv = modelviewproj * vec4(pos, 1);

  gl_Position = rv;
}

"""
var defPS = """
#version 140
in vec3 norm_out;
in vec2 uv_out;
out vec4 outputColor;
uniform sampler2D tex;
void main() {
  outputColor = texture(tex, uv_out);
}

"""
proc GetCompileErrors(shader: GLuint): string =
  var status: GLint
  var infoLogLen: GLsizei
  glGetShaderiv(shader, GL_COMPILE_STATUS.GLenum, addr status)
  if status == GL_FALSE:
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH.GLenum, addr infoLogLen)
    result = newString(infoLogLen)
    glGetShaderInfoLog(shader, infoLogLen, cast[var GLint](nil), result.cstring)
  else:
    result = ""

proc GetIsCompiled(shader: GLuint): bool =
  var rv: GLint = 0
  glGetShaderiv(shader, GL_COMPILE_STATUS.GLenum, addr rv)
  result = (rv != 0)

proc CompileShader(stype: GLenum; source: string): GLuint =
  result = glCreateShader(stype)
  var csource: cstring = source.cstring
  glShaderSource(result, 1.GLsizei, cast[cstringArray](addr csource), nil)
  glCompileShader(result)
  var err = GetCompileErrors(result)
  if err != "":
    error(err)
  if GetIsCompiled(result) == false:
    raise newException(EGraphicsAPI, err)

proc CheckLinkStatus(program: GLuint): tuple[status: GLint, err: string] =
  glGetProgramiv(program, GL_LINK_STATUS, addr result.status)
  if result.status == GL_FALSE:
    var errLen: GLint = 0
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, addr errLen)
    result.err = newString(errLen)
    glGetProgramInfoLog(program, errLen.GLsizei, cast[var GLint](nil), result.err.cstring)

proc CreateProgram(shaders: varargs[GLuint]): GLuint =
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

proc CreateTVertexAttribPtr(program: GLuint): GLuint =
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

proc CreateMeshBuffers(mesh: var TMesh): tuple[vert: GLuint, index: GLuint] =
  glGenBuffers(1, addr result.vert)
  glGenBuffers(1, addr result.index)
  glBindBuffer(GL_ARRAY_BUFFER, result.vert)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.index)
  var vertSize = sizeof(TVertex) * mesh.verts.len
  var indexSize = sizeof(uint32) * mesh.indices.len
  glBufferData(GL_ARRAY_BUFFER, vertSize.GLsizeiptr, addr mesh.verts[0], GL_STATIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, vertSize.GLsizeiptr, addr mesh.indices[0], GL_STATIC_DRAW)
  

proc BindTransforms(program: GLuint; model, view, proj: var TMat4f) =
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

proc CreateTexture(data: GLvoid; width, height: int): GLuint =
  ## creates a texture using immutable texture storage and 
  ## uploads `data` to it.
  glGenTextures(1, addr result)
  glBindTexture(GL_TEXTURE_2D, result)
  glTexStorage2D(GL_TEXTURE_2D, 6, GL_RGBA8, width.GLsizei, height.GLsizei)
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width.GLsizei, height.GLsizei, GL_BGRA, cGL_UNSIGNED_BYTE, data)
  glGenerateMipmap(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, 0)
proc AttachTextureToProgram(texture: GLuint; program: GLuint; texUint: GLint; sampler: string) =
  glUseProgram(program)
  glActiveTexture(GL_TEXTURE0.GLuint + texUint.GLuint)
  glBindTexture(GL_TEXTURE_2D, texture)
  var samplerLoc = glGetUniformLocation(program, sampler.cstring)
  glUniform1i(samplerLoc, texUint)



proc RenderUntextured*(scene: SceneId; meshEnt: var TComponent[TMesh]) {.procvar.} =
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var element = meshEnt.data
  var cameraEnt = matchEnt(scene, TCamera, TTransform)
  var camTrans = EntFirst[TTransform](cameraEnt)
  var modelMatrix = EntFirst[TTransform](meshEnt.id).GenMatrix()
  var cam = EntFirst[TCamera](cameraEnt)
  var diffuseTex = EntFirst[TImage](meshEnt.id)
  var viewMatrix = camTrans.GenMatrix()
  var projMatrix = cam
  #the camera uses the convention where
  #a transform along +Z is toward the camera
  #but GL uses the opposite convention, so we
  #need this multiplication
  viewMatrix.mat(0, 3) *= -1
  viewMatrix.mat(1, 3) *= -1
  viewMatrix.mat(2, 3) *= -1
  #we want clip space to be from -1 to 1
  #but the camera uses the directX convention of
  #0 to 1
  projMatrix.mat(2, 3) *=  2
  if vs == 0: vs = CompileShader(GL_VERTEX_SHADER, defVS)
  if ps == 0: ps = CompileShader(GL_FRAGMENT_SHADER, defPS)
  if program == 0: program = CreateProgram(vs, ps)
  CheckError()
  glUseProgram(program)
  CheckError()
  BindTransforms(program, modelMatrix, viewMatrix, projMatrix)
  #we are going to recreate all our buffers for every draw
  #call because we can. TODO: stop doing this
  var vertSize = sizeof(TVertex) * element.verts.len
  var indexSize = sizeof(uint32) * element.indices.len 
  var buffers = mEntFirstOpt[TObjectBuffers](meshEnt.id)
  if buffers == nil:
    meshEnt.id.add(initObjectBuffers())
    buffers = mEntFirstOpt[TObjectBuffers](meshEnt.id)
    var (vert, index) = CreateMeshBuffers(meshEnt.data)
    buffers.vertex = vert
    buffers.index = index
    buffers.vao = CreateTVertexAttribPtr(program)
    buffers.tex = CreateTexture(diffuseTex.data, diffuseTex.width, diffuseTex.height)
        
  CheckError()
  AttachTextureToProgram(buffers.tex, program, 0, "tex")
  glBindVertexArray(buffers.vao)
  CheckError()
  glBindBuffer(GL_ARRAY_BUFFER.GLenum, buffers.vertex)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER.GLenum, buffers.index)
  CheckError()

  glDrawElements(GL_TRIANGLES, cast[GLSizei](element.indices.len), cGL_UNSIGNED_INT, nil)
  CheckError()

