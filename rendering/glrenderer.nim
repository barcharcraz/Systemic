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
import utils.iterators

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


proc RenderUntextured*(scene: SceneId) {.procvar.} =
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var cameraEnt = first(walk(scene, TCamera, TTransform))[0]
  var camTrans = cameraEnt@TTransform
  var cam = cameraEnt@TCamera
  var viewMatrix = camTrans.GenMatrix()
  var projMatrix = cam.matrix
  viewMatrix = viewMatrix.AdjustViewMatrix()
  projMatrix = projMatrix.AdjustProjMatrix()
  if vs == 0: vs = CompileShader(GL_VERTEX_SHADER, defVS)
  if ps == 0: ps = CompileShader(GL_FRAGMENT_SHADER, defPS)
  if program == 0: program = CreateProgram(vs, ps)
  CheckError()
  glUseProgram(program)
  CheckError()
  for id, model, tex, pos in walk(scene, TMesh, TImage, TTransform):
    BindTransforms(program, pos[].GenMatrix(), viewMatrix, projMatrix)
    var vertSize = sizeof(TVertex) * model.verts.len
    var indexSize = sizeof(uint32) * model.indices.len
    var buffers = id?TObjectBuffers
    if buffers == nil:
      id.add(initObjectBuffers())
      buffers = addr (id@TObjectBuffers)
      var (vert, index) = CreateMeshBuffers(model[])
      buffers.vertex = vert
      buffers.index = index
      buffers.vao = CreateVertexAttribPtr(program, buffers.vertex, buffers.index)
      buffers.tex = CreateTexture(tex.data, tex.width, tex.height)
          
    CheckError()
    AttachTextureToProgram(buffers.tex, program, 0, "tex")
    glBindVertexArray(buffers.vao)
    CheckError()
    glBindBuffer(GL_ARRAY_BUFFER.GLenum, buffers.vertex)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER.GLenum, buffers.index)
    CheckError()

    glDrawElements(GL_TRIANGLES, cast[GLSizei](model[].indices.len), GL_UNSIGNED_INT, nil)
    CheckError()

