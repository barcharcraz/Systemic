import opengl
import components.mesh
import components.camera
import components.transform
import components.image
import components
import ecs.Scene
import ecs.entitynode
import ecs.entity
import ecs.scenenode
import logging
import exceptions
import vecmath
import unsigned
import glcore

var defVS = """
#version 140
struct matrices_t {
  mat4 model;
  mat4 view;
  mat4 proj;
};
uniform matrices_t mvp;

in vec3 pos;
in vec3 norm;
in vec2 uv;
out vec3 norm_out;
out vec2 uv_out;
void main() {
  mat4 modelviewproj = mvp.proj * mvp.view * mvp.model;
  mat4 modelview = mvp.view * mvp.model;
  norm_out = norm;
  uv_out = uv;
  vec4 rv = modelviewproj * vec4(pos, 1);

  gl_Position = rv;
}

"""
var defPS = """
#version 140
in vec3 norm_out;
in vec2 uv_out;
out vec4 outputColor;
uniform sampler2D tex;
void main() {
  outputColor = texture(tex, uv_out);
}

"""


proc RenderUntextured*(scene: SceneId; meshEnt: var TComponent[TMesh]) {.procvar.} =
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var element = meshEnt.data
  var cameraEnt = matchEnt(scene, TCamera, TTransform)
  var camTrans = EntFirst[TTransform](cameraEnt)
  var modelMatrix = EntFirst[TTransform](meshEnt.id).GenMatrix()
  var cam = EntFirst[TCamera](cameraEnt)
  var diffuseTex = EntFirst[TImage](meshEnt.id)
  var viewMatrix = camTrans.GenMatrix()
  var projMatrix = cam
  #the camera uses the convention where
  #a transform along +Z is toward the camera
  #but GL uses the opposite convention, so we
  #need this multiplication
  viewMatrix.mat(0, 3) *= -1
  viewMatrix.mat(1, 3) *= -1
  viewMatrix.mat(2, 3) *= -1
  #we want clip space to be from -1 to 1
  #but the camera uses the directX convention of
  #0 to 1
  projMatrix.mat(2, 3) *=  2
  if vs == 0: vs = CompileShader(GL_VERTEX_SHADER, defVS)
  if ps == 0: ps = CompileShader(GL_FRAGMENT_SHADER, defPS)
  if program == 0: program = CreateProgram(vs, ps)
  CheckError()
  glUseProgram(program)
  CheckError()
  BindTransforms(program, modelMatrix, viewMatrix, projMatrix)
  var vertSize = sizeof(TVertex) * element.verts.len
  var indexSize = sizeof(uint32) * element.indices.len 
  var buffers = mEntFirstOpt[TObjectBuffers](meshEnt.id)
  if buffers == nil:
    meshEnt.id.add(initObjectBuffers())
    buffers = mEntFirstOpt[TObjectBuffers](meshEnt.id)
    var (vert, index) = CreateMeshBuffers(meshEnt.data)
    buffers.vertex = vert
    buffers.index = index
    buffers.vao = CreateVertexAttribPtr(program)
    buffers.tex = CreateTexture(diffuseTex.data, diffuseTex.width, diffuseTex.height)
        
  CheckError()
  AttachTextureToProgram(buffers.tex, program, 0, "tex")
  glBindVertexArray(buffers.vao)
  CheckError()
  glBindBuffer(GL_ARRAY_BUFFER.GLenum, buffers.vertex)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER.GLenum, buffers.index)
  CheckError()

  glDrawElements(GL_TRIANGLES, cast[GLSizei](element.indices.len), cGL_UNSIGNED_INT, nil)
  CheckError()

