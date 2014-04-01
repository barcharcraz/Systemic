import vecmath
import opengl
import ecs
import logging
import components/transform

proc findSelected(transforms: openarray[TComponent[TTransform]], x,y: float, mtx: TMat4f): EntityId =
  var color: TVec4[GLByte]
  var depth: GLfloat
  var index: GLuint

  glReadPixels(x.GLint, y.GLint, 1, 1, GL_RGBA, cGL_UNSIGNED_BYTE, addr color.data[0])
  glReadPixels(x.GLint, y.GLint, 1, 1, GL_DEPTH_COMPONENT, cGL_FLOAT, addr depth)
  glReadPixels(x.GLint, y.GLint, 1, 1, GL_STENCIL_INDEX, cGL_UNSIGNED_INT, addr index)
  var viewport: TVec4f
  glGetFloatv(cGL_VIEWPORT, addr viewport.data[0])
  var selectedPos = unProject(vec3f(x,y,depth), mtx, viewport)
  debug("Selected: " & $selectedPos)
  var maxDist = 10.0
  for elm in transforms:
    var sdist = dist(selectedPos, elm.position)
    if sdist <= maxDist:
      return elm.id
  return (-1).EntityId
proc handleSelectionAttempt*(scene: SceneId, x,y: float)
  var (cam, camTrans) = entComponents(scene, TCamera, TTransform)
  var viewMtx = camTrans[].GenRotTransMatrix().AdjustViewMatrix()
  var projMtx = cam[].AdjustProjMatrix()
  var transfms = addr components(scene, TTransform)
  var selected = findSelected(transfms[], x, y, mul(proj, view))
  debug("Selected Entity: " & $selected.int)
