import ecs
import os
import glfw/glfw
import opengl
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
import gui.button
import gui.widgetcomps
import gui.listbox
import utils.memory
import rendering.glcore
var log = newConsoleLogger()
handlers.add(log)
const winw = 640
const winh = 480
#cairo code
var cairo_surface = image_surface_create(FORMAT_ARGB32, winw, winh)
var cairo_ctx = create(cairo_surface)


glfw.init()
var api = initGL_API(glv31, false, false, glpAny, glrNone)
var wnd = newWin(dim = (w: winw, h: winh), title = "GL test", GL_API=api, refreshRate = 1)
makeContextCurrent(wnd)
wnd.cursorMode = cmDisabled
AttachInput(wnd)
var done = false
var mainscene = initScene()
#mainscene.id.addComponent(initDirectionalLight(vec3f(0.0'f32,0.0'f32,-1.0'f32)))
mainscene.id.addComponent(initPointLight(vec3f(0.0'f32, 0.0'f32, -30.0'f32)))
mainscene.id.addComponent(new(initListBox(vec2f(20,20), vec2f(100,100))))
mainscene.id.addComponent(new(initButton(vec2f(20,20), "test")))
var camEnt = mainscene.id.addCamera()
var inp = initShooterKeys()
camEnt.add(addr inp)
wnd.mouseBtnCb = proc(wnd: PWin, btn: TMouseBtn, pressed: bool, modKeys: TModifierKeySet) =
  var mouseInfo = pollMouse(wnd)
  if input.mbLeft in mouseInfo.buttons:
    handleSelectionAttempt(mainscene.id, mouseInfo.x, mouseInfo.y)
mainscene.id.addStaticMesh("assets/sphere.obj", "assets/diffuse.tga", vec3f(0,0,-10))
mainscene.id.addStaticMesh("assets/testobj.obj", "assets/diffuse.tga", vec3f(3,0,-5))
mainscene.addSystem(AccelerationSystem)
mainscene.addSystem do (scene: SceneId): 
  inp.Update(pollInput(wnd))
  MovementSystem(scene, inp, camEnt)
mainscene.addSystem(movement.VelocitySystem)
mainscene.addSystem do (ts: var openarray[ref TButton]): doButtonCollision(pollMouse(wnd), ts)
mainscene.addSystem do (ts: openarray[ref TButton]): drawButtons(cairo_ctx, ts)
mainscene.addSystem do: RenderUI(cairo_ctx)
mainscene.addSystem(PrimitiveRenderSystem)
mainscene.addSystem(RenderPhongLit)
initOpenGLRenderer()
glViewport(0,0,winw,winh)
glClearColor(1.0'f32, 0.0'f32, 0.0'f32, 1.0'f32)
while not done and not wnd.shouldClose:
  PrimCylinder()
  mainscene.update()
  
  wnd.handleMouse()
  wnd.update()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
wnd.destroy()
glfw.terminate()

