import vecmath
import utils/log
import opengl
import rendering/glcore
import ecs
import components
import strutils
import components/selectDat
const selectionDbg = true
loggingWrapper(selectionDbg)


proc findSelected(transforms: openarray[TComponent[TTransform]], x,y: float, mtx: TMat4f): EntityId =
  var color: TVec4[GLByte]
  var depth: GLfloat
  var index: GLuint
  
  var viewport: TVec4f
  glGetFloatv(cGL_VIEWPORT, addr viewport.data[0])
  debug("Click was at x: " & formatFloat(x) & " y: " & formatFloat(y))
  debug("viewport is w: " & $formatFloat(viewport[3]) & " h: " & formatFloat(viewport[4]))
  glReadPixels(x.GLint, (viewport[4] - y).GLint, 1, 1, GL_RGBA, cGL_UNSIGNED_BYTE, addr color.data[0])
  glReadPixels(x.GLint, (viewport[4] - y).GLint, 1, 1, GL_DEPTH_COMPONENT, cGL_FLOAT, addr depth)
  glReadPixels(x.GLint, (viewport[4] - y).GLint, 1, 1, GL_STENCIL_INDEX, cGL_UNSIGNED_INT, addr index)
  #if depth >= 0.99999'f32: return (-1).EntityId
  debug("mtx is: "& repr(mtx))
  var selectedPos = unProject(vec3f(x,y,depth), mtx, viewport)
  debug("Selected: " & vecmath.`$`(selectedPos))
  debug("Depth Value: " & formatFloat(depth))
  var maxDist = 4.0
  for elm in transforms:
    var sdist = dist(selectedPos, elm.data.position)
    debug("Distance to ent: " & $elm.id.int & " is: " & formatFloat(sdist))
    if sdist <= maxDist:
      return elm.id
  return (-1).EntityId
proc handleSelectionAttempt*(scene: SceneId, x,y: float) =
  var (cam, camTrans) = entComponents(scene, TCamera, TTransform)
  var viewMtx = camTrans[].GenRotTransMatrix().AdjustViewMatrix()
  var projMtx = cam[].AdjustProjMatrix()
  var transfms = addr components(scene, TComponent[TTransform])
  var selected = findSelected(transfms[], x, y, mul(projMtx, viewMtx))
  debug("Selected Entity: " & $selected.int)
  if selected == (-1).EntityId: return
  var callbck = mEntFirstOpt[onMouseDown](selected)
  if callbck != nil: callbck[](x,y)
  
