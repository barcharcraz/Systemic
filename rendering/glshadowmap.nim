import opengl
import glcore
import vecmath
import ecs
import glshaders
import exceptions
import unsigned
import components
import math
import utils/iterators
var defvs = """
#version 140
uniform mat4 lightTransform;
in vec3 pos;

void main() {
  gl_Position = lightTransform * vec4(pos, 1);
}
"""
var defps = """
#version 140

out float fragDepth;
void main() {
  fragDepth = gl_FragCoord.z;
}
"""
type TShadowMap = object
  depthTex: GLuint
MakeEntityComponent(TShadowMap)

proc RenderShadowMaps*(scene: SceneId) {.procvar.} =
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var fbo {.global.}: GLuint
  var projmtx = CreateOrthoMatrix(vec3f(-20, -20, 20), vec3f(20, 20, -20))
  if vs == 0 or ps == 0:
    vs = CompileShader(GL_VERTEX_SHADER, defvs)
    ps = CompileShader(GL_FRAGMENT_SHADER, defps)
    program = CreateProgram(vs, ps)
  if fbo == 0:
    glGenFramebuffers(1, addr fbo)
  glUseProgram(program)
  glBindFrameBuffer(GL_FRAMEBUFFER, fbo)
  #glUniformMatrix4fv(transformIdx, 1.GLsizei, false, cast[ptr GLfloat](addr projmtx.data[0]))
  glDrawBuffer(GL_NONE)
  var oldView: array[1..4, GLint]
  glGetIntegerv(cGL_VIEWPORT, addr oldView[1])
  glViewport(0,0,1024,1024)
  for id, light, map in walk(scene, TDirectionalLight, TShadowMap, create = true):
    var viewMtx = CalcViewMatrix(light[].direction.xyz)
    if map[].depthTex == 0:
      map[].depthTex = InitializeDepthBuffer(1024)
    glFrameBufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, map[].depthTex, 0)
    glClear(GL_DEPTH_BUFFER_BIT)
    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
      raise newException(EFramebufferInvalid, "")
    for id, mesh, buffers, trans in scene.walk(TMesh, TObjectBuffers, TTransform):
      var mvmtx = mul(projmtx, viewMtx)
      mvmtx = mul(mvmtx, trans[].GenMatrix())
      var transformIdx = glGetUniformLocation(program, "lightTransform")
      glUniformMatrix4fv(transformIdx, 1.GLsizei, false, cast[ptr GLfloat](addr mvmtx.data[0]))
      glBindVertexArray(buffers[].vao)
      glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[].index)
      glDrawElements(GL_TRIANGLES, cast[GLSizei](mesh.indices.len), GL_UNSIGNED_INT, nil)
  glBindFrameBuffer(GL_FRAMEBUFFER, 0)
  glViewport(oldView[1], oldView[2], oldView[3], oldView[4])
    
    
