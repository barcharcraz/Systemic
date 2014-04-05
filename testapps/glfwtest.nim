import ecs
import os
import glfw/glfw
import opengl
import input
import rendering.glrenderer
import rendering.glphong
import components.mesh
import components.camera
import components.transform
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
import gui.button
import gui.widgetcomps
import rendering.glcore
import buildopts
var log = newConsoleLogger()
handlers.add(log)
const winw = 640
const winh = 480
#cairo code
var cairo_surface = image_surface_create(FORMAT_ARGB32, winw, winh)
var cairo_ctx = create(cairo_surface)


glfw.init()
var api = initGL_API(glv31, false, false, glpAny, glrNone)
var winhints = initHints(GL_API = api)
var wnd = newWnd(dim = (w: winw, h: winh), title = "GL test", hints = winhints)
makeContextCurrent(wnd)
#loadExtensions()
var done = false
var mainscene = initScene()
var tmesh = loadMesh("assets/sphere.obj")
var torus = loadMesh("assets/testobj.obj")
var camEnt = genEntity()
var meshEnt = genEntity()
var torusEnt = genEntity()
#mainscene.id.addComponent(initDirectionalLight(vec3f(0.0'f32,0.0'f32,-1.0'f32)))
mainscene.id.addComponent(initPointLight(vec3f(0.0'f32, 0.0'f32, -30.0'f32)))
mainscene.id.addComponent(initButton(vec2f(20,20), "test"))
mainscene.id.add(camEnt)
mainscene.id.add(meshEnt)
mainscene.id.add(torusEnt)
camEnt.add(initCamera())
camEnt.add(initTransform(vec3f(0,0,0)))
#camEnt.add(initVelocity().TPremulVelocity)
var inp = initShooterKeys()
camEnt.add(addr inp)
wnd.mouseBtnCb = proc(wnd: PWnd, btn: TMouseBtn, pressed: bool, modKeys: TModifierKeySet) =
  var mouseInfo = pollMouse(wnd)
  if input.mbLeft in mouseInfo.buttons:
    handleSelectionAttempt(mainscene.id, mouseInfo.x, mouseInfo.y)
wnd.cursorPosCb = proc(wnd: PWnd, pos: tuple[x,y: float64]) =
  var lastPos {.global.}: TMouse
  var mouseInfo = pollMouse(wnd)
  var dx = mouseInfo.x - lastPos.x
  var dy = mouseInfo.y - lastPos.y
  lastPos = mouseInfo
  if input.mbRight in mouseInfo.buttons:
    OrbitSelectionMovement(mainscene.id, dx, dy)
  
meshEnt.add(tmesh)
meshEnt.add(initMaterial())
meshEnt.add(initAcceleration())
meshEnt.add(initTransform(vec3f(0.0'f32, 0.0'f32, -10.0'f32)))
meshEnt.add(getTexture("assets/diffuse.tga"))
meshEnt.add(initVelocity(quatFromAngleAxis(0.00, vec3f(1,0,0))))
torusEnt.add(torus)
torusEnt.add(initMaterial())
torusEnt.add(initTransform(vec3f(3.0'f32, 0.0'f32, -5.0'f32)))
torusEnt.add(getTexture("assets/diffuse.tga"))
#mainscene.addSystem(MovementSystem)
#mainscene.addSystem(OrbitSystem)
#mainscene.addSystem(AccelerationSystem)
#mainscene.addSystem(movement.VelocitySystem)
mainscene.addSystem do (ts: var openarray[TBUtton]): doButtonCollision(pollMouse(wnd), ts)
mainscene.addSystem do (ts: openarray[TButton]): drawButtons(cairo_ctx, ts)
mainscene.addSystem do: RenderUI(cairo_ctx)
mainscene.addSystem(RenderPhongLit)
initOpenGLRenderer()
glViewport(0,0,winw,winh)
glClearColor(1.0'f32, 0.0'f32, 0.0'f32, 1.0'f32)
while not done and not wnd.shouldClose:
  mainscene.update()
  
  wnd.handleMouse()
  wnd.update()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
wnd.destroy()
glfw.terminate()

