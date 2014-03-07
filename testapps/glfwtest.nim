import os
import glfw/glfw
import opengl
import ecs.scenenode
import ecs.scene
import ecs.entitynode
import ecs.entity
import renderers.glrenderer
import components.mesh
import components.camera
import components.transform
import components
import logging
var log = newConsoleLogger()
handlers.add(log)

glfw.init()
var api = initGL_API(glv31, false, true, glpAny, glrNone)
var winhints = initHints(GL_API = api)
var wnd = newWnd(title = "GL test", hints = winhints)
makeContextCurrent(wnd)
#loadExtensions()
var done = false

var mainscene = initScene()
var tmesh: TMesh
tmesh.verts = @[]
tmesh.verts.add(initVertex([-5.0'f32, 0.0'f32, -10.0'f32]))
tmesh.verts.add(initVertex([0.0'f32, 5.0'f32, -10.0'f32]))
tmesh.verts.add(initVertex([5.0'f32, 0.0'f32, -10.0'f32]))
tmesh.indices = @[0.uint32, 1.uint32, 2.uint32]
var camEnt = genEntity()
var meshEnt = genEntity()
mainscene.id.add(camEnt)
mainscene.id.add(meshEnt)
camEnt.add(initCamera())
camEnt.add(initTransform())
meshEnt.add(tmesh)
meshEnt.add(initTransform())
mainscene.addSystem(glrenderer.RenderUntextured)
initOpenGLRenderer()
glViewport(0,0,640,480)
glClearColor(1.0'f32, 0.0'f32, 0.0'f32, 1.0'f32)
while not done and not wnd.shouldClose:
  mainscene.update()
  wnd.update()
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or GL_STENCIL_BUFFER_BIT)
wnd.destroy()
glfw.terminate()

