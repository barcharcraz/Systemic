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
import glfwinput
import components
import logging
import assetloader
import vecmath
import cairo
import gui.caiglrender
import gui.button
import gui.widgetcomps
import rendering.glcore
var log = newConsoleLogger()
handlers.add(log)

#cairo code
var cairo_surface = image_surface_create(FORMAT_ARGB32, 1920, 1080)
var cairo_ctx = create(cairo_surface)


glfw.init()
var api = initGL_API(glv31, false, false, glpAny, glrNone)
var winhints = initHints(GL_API = api)
var wnd = newWnd(dim = (w: 1920, h: 1080), title = "GL test", hints = winhints)
makeContextCurrent(wnd)
#loadExtensions()
var done = false
var mainscene = initScene()
var tmesh = loadMesh("assets/testobj.obj")
var camEnt = genEntity()
var meshEnt = genEntity()
#mainscene.id.addComponent(initDirectionalLight([0.0'f32,0.0'f32,1.0'f32]))
mainscene.id.addComponent(initPointLight(vec3f(4.0'f32, 0.0'f32, -3.0'f32)))
mainscene.id.addComponent(initButton(vec2f(20,20)))
mainscene.id.add(camEnt)
mainscene.id.add(meshEnt)
camEnt.add(initCamera())
camEnt.add(initTransform())
camEnt.add(initVelocity().TPremulVelocity)
var inp = initShooterKeys()
camEnt.add(addr inp)
AttachInput(wnd, inp)
meshEnt.add(tmesh)
meshEnt.add(initMaterial())
meshEnt.add(initAcceleration())
meshEnt.add(initTransform(vec3f(0.0'f32, 0.0'f32, -10.0'f32)))
meshEnt.add(getTexture("assets/diffuse.tga"))
meshEnt.add(initVelocity((vec3f(0.005'f32, 0.0'f32, 0.0'f32))))
mainscene.addSystem(MovementSystem)
mainscene.addSystem(OrbitSystem)
mainscene.addSystem(AccelerationSystem)
mainscene.addSystem(movement.VelocitySystem)
mainscene.addSystem do (ts: var openarray[TBUtton]): doButtonCollision(pollMouse(wnd), ts)
mainscene.addSystem do (ts: openarray[TButton]): drawButtons(cairo_ctx, ts)
mainscene.addSystem do: RenderUI(cairo_ctx)
mainscene.addSystem(RenderPhongLit)
initOpenGLRenderer()
glViewport(0,0,1920,1080)
glClearColor(1.0'f32, 0.0'f32, 0.0'f32, 1.0'f32)
while not done and not wnd.shouldClose:
  mainscene.update()
  
  wnd.handleMouse()
  wnd.update()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
wnd.destroy()
glfw.terminate()

