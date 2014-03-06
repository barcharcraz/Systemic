import opengl
import components.mesh
import components.camera
import ecs.Scene

proc initOpenGlRenderer() =
  loadExtensions()
  glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LEQUAL)
  glDepthMask(GL_TRUE)
  glDepthRange(0.0, 1.0)
  glEnable(GL_CULL_FACE)
  glFrontFace(GL_CW)


proc RenderUntextured(scene: SceneId; elements: openarray[TMesh]) =
  var cam = scene.getAny[TCamera]