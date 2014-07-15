import opengl
import glcore
import vecmath
import ecs
import glshaders
import exceptions
import unsigned
import components
import math
import genutils
import utils/iterators
import prims
import culling
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
const shadowMapRes = 1024
proc findLightMatrix(scene: SceneId): TMat4f =
  var bbox = BruteForceFrustum(scene)
  #bbox.max = bbox.max + vec3f(10,10,10)
  #bbox.min = bbox.min - vec3f(10,10,10)
  swap(bbox.max.data[2], bbox.min.data[2])
  echo bbox
  #bbox.min = vec3f(-20, -20, 20)
  #bbox.max = vec3f(20,20,-20)
  var prim {.global.}: EntityId
  if prim == 0.EntityId:
    prim = genEntity()
    scene.add(prim)
    prim.add(PrimBoundingBox(bbox))
  else:
    prim@TPrim = PrimBoundingBox(bbox)
  result = CreateOrthoMatrix(bbox)
proc RenderShadowMaps*(scene: SceneId) {.procvar.} =
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var fbo {.global.}: GLuint
  var projmtx = findLightMatrix(scene)
  #var projmtx = CreateOrthoMatrix(vec3f(-20, -20, 20), vec3f(20, 20, -20))
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
  glReadBuffer(GL_NONE)
  var oldView: array[1..4, GLint]
  glGetIntegerv(cGL_VIEWPORT, addr oldView[1])
  glViewport(0,0,shadowMapRes,shadowMapRes)
  glCullFace(GL_FRONT)
  for id, light, map in walk(scene, TDirectionalLight, TShadowMap, create = true):
    var viewMtx = CalcViewMatrix(light[].direction.xyz)
    if map[].depthTex == 0:
      map[].depthTex = InitializeDepthBuffer(shadowMapRes)
    map[].shadowVP = mul(projmtx, viewMtx)
    map[].shadowVP = mul(BiasMatrix, map[].shadowVP)
    glFrameBufferTexture(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, map[].depthTex, 0)
    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
      raise newException(EFramebufferInvalid, "")
    glClear(GL_DEPTH_BUFFER_BIT)
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
  glCullFace(GL_BACK)
    
    
