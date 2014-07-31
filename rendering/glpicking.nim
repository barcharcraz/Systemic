##implements color picking rendering, this means we
##render the whole scene with colors that corospond to
##entityIDs

import opengl
import glcore
import ecs
import components
const PickingPS* = """
#version 140
uniform uint ent;
out vec4 outputColor;
void main() {
  outputColor = vec4(color,1);
}
"""
proc RenderSceneForPicking*(scene: SceneId): GLuint =
  ## returns an opengl handle to the frambuffer object
  ## that we just rendered on, so that the caller can bind it
  ## and use glReadPixels and the like
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var fbo {.global.}: GLuint
  var (cament, camera, camtrans) = first(walk(scene, TCamera, TTransform))
  if vs == 0 or ps == 0:
    vs = CompileShader(GL_VERTEX_SHADER, BasicVS)
    ps = CompileShader(GL_FRAGMENT_SHADER, PickingPS)
    program = CreateProgram(vs, ps)
  if fbo == 0:
    glGenFramebuffer(GL_FRAMEBUFFER, addr fbo)
    var viewport: TVec4f
    glGetIntegerv(cGL_VIEWPORT, addr viewport.data[0])
    glBindFramebuffer(GL_FRAMEBUFFER, fbo)
    var color, depth: GLuint
    glGenRenderbuffers(1, addr color)
    glGenRenderbuffers(1, addr depth)
    glBindRenderbuffer(GL_RENDERBUFFER, color)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, viewport[3], viewport[4])
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, color)
    glBindRenderbuffer(GL_RENDERBUFFER, depth)
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT_24, viewport[3], viewport[4])
  glUseProgram(program)
  glBindFramebuffer(GL_FRAMEBUFFER, fbo)

