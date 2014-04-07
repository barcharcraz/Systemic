import ecs
import os
import glfw/glfw
import opengl
import input
import prefabs
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
AttachInput(wnd)
var done = false
var mainscene = initScene()
var camEnt = genEntity()
#mainscene.id.addComponent(initDirectionalLight(vec3f(0.0'f32,0.0'f32,-1.0'f32)))
mainscene.id.addComponent(initPointLight(vec3f(0.0'f32, 0.0'f32, -30.0'f32)))
mainscene.id.addComponent(initButton(vec2f(20,20), "test"))
mainscene.id.add(camEnt)
camEnt.add(initCamera())
camEnt.add(initTransform(vec3f(0,0,0)))
camEnt.add(initVelocity().TPremulVelocity)
var inp = initShooterKeys()
camEnt.add(addr inp)
wnd.mouseBtnCb = proc(wnd: PWnd, btn: TMouseBtn, pressed: bool, modKeys: TModifierKeySet) =
  var mouseInfo = pollMouse(wnd)
  if input.mbLeft in mouseInfo.buttons:
    handleSelectionAttempt(mainscene.id, mouseInfo.x, mouseInfo.y)
discard """
wnd.cursorPosCb = proc(wnd: PWnd, pos: tuple[x,y: float64]) =
  var lastPos {.global.}: TMouse
  var mouseInfo = pollMouse(wnd)
  var dx = mouseInfo.x - lastPos.x
  var dy = mouseInfo.y - lastPos.y
  lastPos = mouseInfo
  inp.mouse.x = dx
  inp.mouse.y = dy
  MovementSystem(mainscene.id, inp, camEnt)
  #if input.mbRight in mouseInfo.buttons:
  #  OrbitSelectionMovement(mainscene.id, dx, dy)
wnd.keyCb = proc(wnd: PWnd, key: glfw.TKey, scan: int, action: TKeyAction, modKeys: TModifierKeySet) =
  inp.pressed = pollKeyboard(wnd)
  MovementSystem(mainscene.id, inp, camEnt)
"""
mainscene.id.addStaticMesh("assets/sphere.obj", "assets/diffuse.tga", vec3f(0,0,-10))
mainscene.id.addStaticMesh("assets/testobj.obj", "assets/diffuse.tga", vec3f(3,0,-5))
#mainscene.addSystem(MovementSystem)
#mainscene.addSystem(OrbitSystem)
#mainscene.addSystem(AccelerationSystem)
mainscene.addSystem do (scene: SceneId): 
  inp.Update(pollInput(wnd))
  MovementSystem(scene, inp, camEnt)
mainscene.addSystem(movement.VelocitySystem)
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

