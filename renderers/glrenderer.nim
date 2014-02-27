import opengl


proc initOpenGlRenderer() =
  loadExtensions()
  glEnable(GL_DEPTH_TEST)
  glDepthFunc(GL_LEQUAL)
  glDepthMask(GL_TRUE)
  glDepthRange(0.0, 1.0)
  glEnable(GL_CULL_FACE)
  glFrontFace(GL_CW)
