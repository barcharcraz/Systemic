import ecs
import os
import glfw/glfw
import opengl
import math
import colors
import input
import prefabs
import rendering.glrenderer
import rendering.glphong
import rendering.glprims
import systems.movement
import systems.orbit
import systems.selection
import glfwinput
import components
import logging
import assetloader
import vecmath
import cairo
import strutils
import gui.caiglrender
import widgets
import editor
import gametime
import utils.memory
import rendering.glcore
import rendering.glshadowmap
import spacial
import prims


var log = newConsoleLogger()
handlers.add(log)

const winw = 800
const winh = 600
#cairo code
var cairo_surface = image_surface_create(FORMAT_ARGB32, winw, winh)
var cairo_ctx = create(cairo_surface)
#UI initialization
var frame: seq[ref TWidget] = @[]
var listBox = new(initListBox(vec2f(20,20)))
#listBox.add(new(initButton(vec2f(20,20))))
#listBox.add(new(initButton(vec2f(20,20))))
frame.add(listBox)
#glfw initialization
glfw.init()
when defined(macosx):
  var glversion = glv32
  var forwardcompat = true
  var profile = glpCore
else:
  var glversion = glv31
  var forwardcompat = false
  var profile = glpAny
var api = initGL_API(glversion, forwardcompat, true, profile, glrNone)
var wnd = newWin(dim = (w: winw, h: winh), title = "GL test", GL_API=api, refreshRate = 1)
makeContextCurrent(wnd)
wnd.cursorMode = cmDisabled

AttachInput(wnd)
var done = false
var mainscene = initScene()
mainscene.id.addDirectionalLight(vec3f(1.0'f32, -1.0'f32, 0.0'f32).normalize())
#mainscene.id.addComponent(initDirectionalLight(vec3f(0.0'f32,0.0'f32,-1.0'f32)))
#mainscene.id.addSpotLight(vec3f(0, 2, -2), vec3f(0,-1,0), colBlue)

var camEnt = mainscene.id.addCamera(fov = 800/600)
var inp = initShooterKeys()
inp.AddAction("FreeLook", {input.keyLeftShift})
inp.AddAction("select", {input.mbRight})
camEnt.add(addr inp)

mainscene.id.addStaticMesh("assets/sphere.obj", "assets/diffuse.tga", vec3f(10,0,-2))
#mainscene.id.addStaticMesh("assets/sphere.obj", "assets/diffuse.tga", vec3f(10, 10,-45))
#mainscene.id.addStaticMesh("assets/sphere.obj", "assets/diffuse.tga", vec3f(-10,5,-25))
#mainscene.id.addStaticMesh("assets/sphere.obj", "assets/diffuse.tga", vec3f(5,0,-20))
var testObj = mainscene.id.addStaticMesh("assets/testobj.obj", "assets/diffuse.tga", vec3f(5,0,-5))
(testObj@TTransform).rotation = quatFromAngleAxis(PI/2, vec3f(1,0,0))
mainscene.id.addStaticMesh("assets/land.obj", "assets/diffuse.tga", vec3f(0,-5,0))
populateAssets(listBox, "assets", "*.obj")
UpdateAABBs(mainscene.id)

#for id, aabb in walk(mainscene.id, TAxisAlignedBB):
#  mainscene.id.add(PrimBoundingBox(aabb[].curAABB))

initOpenGLRenderer()
glViewport(0,0,winw,winh)
glClearColor(0.0'f32, 0.0'f32, 0.0'f32, 1.0'f32)
echo mainscene.id.int
proc UpdateAll(scene: SceneId) =
  inp.Update(pollInput(wnd))
  if inp.Action("FreeLook"): wnd.cursorMode = cmDisabled
  else: wnd.cursorMode = cmNormal

  AccelerationSystem(scene)
  EditorMovementSystem(scene, inp, not inp.Action("FreeLook"))
  VelocitySystem(scene)
  HandleAllInput(frame, pollInput(wnd))
  RenderPhongLit(scene)
  PrimitiveRenderSystem(scene)
  RenderShadowMaps(scene)
  SelectionSystem(scene, inp)
  DrawWidgets(cairo_ctx, frame)
  RenderUI(cairo_ctx)
while not done and not wnd.shouldClose:
  UpdateGameTime()
  UpdateAll(mainscene.id)
  wnd.handleMouse()
  wnd.update()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
  
wnd.destroy()
glfw.terminate()








