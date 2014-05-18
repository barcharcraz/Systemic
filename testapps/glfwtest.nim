import ecs
import os
import glfw/glfw
import opengl
import math
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
import utils.memory
import rendering.glcore
var log = newConsoleLogger()
handlers.add(log)
const winw = 640
const winh = 480
#cairo code
var cairo_surface = image_surface_create(FORMAT_ARGB32, winw, winh)
var cairo_ctx = create(cairo_surface)

var frame: seq[ref TWidget] = @[]
var listBox = new(initListBox(vec2f(20,20)))
#listBox.add(new(initButton(vec2f(20,20))))
#listBox.add(new(initButton(vec2f(20,20))))
frame.add(listBox)

glfw.init()
when defined(macosx):
  var glversion = glv32
  var forwardcompat = true
  var profile = glpCore
else:
  var glversion = glv42
  var forwardcompat = false
  var profile = glpAny
var api = initGL_API(glversion, forwardcompat, true, profile, glrNone)
var wnd = newWin(dim = (w: winw, h: winh), title = "GL test", GL_API=api, refreshRate = 1)
makeContextCurrent(wnd)
wnd.cursorMode = cmDisabled

AttachInput(wnd)
var done = false
var mainscene = initScene()
#mainscene.id.addDirectionalLight(vec3f(0.0'f32, 0.0'f32, -1.0'f32))
#mainscene.id.addComponent(initDirectionalLight(vec3f(0.0'f32,0.0'f32,-1.0'f32)))
for i in 1..1000:
  var x = random[float32](-5.0..5.0)
  var y = random[float32](-5.0..5.0)
  var z = random[float32](-10.0..0.0)
  mainscene.id.addPointLight(vec3f(x,y,z))

var camEnt = mainscene.id.addCamera()
var inp = initShooterKeys()
camEnt.add(addr inp)
wnd.mouseBtnCb = proc(wnd: PWin, btn: TMouseBtn, pressed: bool, modKeys: TModifierKeySet) =
  var mouseInfo = pollMouse(wnd)
  if input.mbLeft in mouseInfo.buttons:
    handleSelectionAttempt(mainscene.id, mouseInfo.x, mouseInfo.y)
mainscene.id.addStaticMesh("assets/sphere.obj", "assets/diffuse.tga", vec3f(0,0,-10))
mainscene.id.addStaticMesh("assets/testobj.obj", "assets/diffuse.tga", vec3f(3,0,-5))
populateAssets(listBox, "assets", "*.obj")
mainscene.addSystem(AccelerationSystem)
mainscene.addSystem do (scene: SceneId): 
  inp.Update(pollInput(wnd))
  MovementSystem(scene, inp, camEnt)
mainscene.addSystem(movement.VelocitySystem)
mainscene.addSystem do:
  handleAllInput(frame, pollInputAbsolute(wnd))
mainscene.addSystem do: 
  for elm in frame: draw(cairo_ctx, elm)
mainscene.addSystem do: RenderUI(cairo_ctx)
mainscene.addSystem(PrimitiveRenderSystem)
mainscene.addSystem(RenderPhongLit)
initOpenGLRenderer()
proc glDebugProc(source: GLEnum, typ: GLenum, id: GLuint,
                 severity: GLenum, len: GLsizei, message: ptr GLchar,
                 userParam: pointer) {.stdcall.} =
  echo( "Debug call" & $message)
glDebugMessageCallbackARB(glDebugProc, nil)
glViewport(0,0,winw,winh)
glClearColor(0.0'f32, 0.0'f32, 0.0'f32, 1.0'f32)
while not done and not wnd.shouldClose:
  mainscene.update()
  wnd.handleMouse()
  wnd.update()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
wnd.destroy()
glfw.terminate()

