import opengl
import glshaders
import glcore
import ecs
import components
import unsigned
import logging

var defVS = """
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
out vec3 view_pos;
out vec2 uv_out;

void main() {
    uv_out = uv;
    mat4 modelviewproj = mvp.proj * mvp.view * mvp.model;
    mat4 modelview = mvp.view * mvp.model;
    gl_Position = modelviewproj * vec4(pos, 1);
    view_pos = (modelview * vec4(pos,1)).xyz;
    norm_out = mat3(modelview) * norm;
}
"""
var version = "#version 140\n"
var defPS = """
""" & LightStructs & ForwardLighting & """
in vec3 norm_out;
in vec3 view_pos;
in vec2 uv_out;
out vec4 outputColor;
layout(std140) uniform dlightBlock {
  directionalLight_t dlights[NUM_DIRECTIONAL];
};
layout(std140) uniform plightBlock {
  pointLight_t plights[NUM_POINT];
};
uniform material_t mat;
uniform sampler2D tex;
void main() {
  outputColor = mat.ambiant;
  for(int i = 0; i < NUM_DIRECTIONAL; ++i) {
    outputColor += directionalLight(dlights[i], vec4(norm_out,1), vec4(view_pos,1), mat);
  }
  for(int i = 0; i < NUM_POINT; ++i) {
    outputColor += pointLight(plights[i], vec4(norm_out, 1), vec4(view_pos,1), mat);
  }
  outputColor = clamp(outputColor, 0.0, 1.0);
  outputColor = outputColor * texture(tex, vec2(uv_out.x, 1 - uv_out.y));
}

"""

proc RenderPhongLit*(scene: SceneId) {.procvar.} =
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var dlightsUniform {.global.}: GLuint
  var plightsUniform {.global.}: GLuint
  #var dlights = GetDefaultNode[TDirectionalLight]().sceneList[scene.int]
  var dlights = components(scene, TDirectionalLight)
  var plights = components(scene, TPointLight)
  if vs == 0 or ps == 0:
    var def = genDefine("NUM_DIRECTIONAL", dlights.len)
    var pdef = genDefine("NUM_POINT", plights.len)
    vs = CompileShader(GL_VERTEX_SHADER, version & def & pdef & defVS)
    ps = CompileShader(GL_FRAGMENT_SHADER, version & def & pdef & defPS)
    program = CreateProgram(vs, ps)
  CheckError()
  var dlightsIdx = glGetUniformBlockIndex(program, "dlightBlock")
  var plightsIdx = glGetUniformBlockIndex(program, "plightBlock")
  if dlightsIdx == GL_INVALID_INDEX:
    warn("dlights is an invalid index")
  if dlightsUniform == 0:
    dlightsUniform = CreateUniformBuffer(dlights)
    glUniformBlockBinding(program, dlightsIdx, 0)
  if plightsUniform == 0:
    plightsUniform = CreateUniformBuffer(plights)
    glUniformBlockBinding(program, plightsIdx, 1)
  CheckError()
  glBindBufferBase(GL_UNIFORM_BUFFER, 0, dlightsUniform)
  glBindBufferBase(GL_UNIFORM_BUFFER, 1, plightsUniform)
  CheckError()
  var (cam, camTrans) = entComponents(scene, TCamera, TTransform)
  var viewMatrix = camTrans[].GenMatrix().AdjustViewMatrix()
  var projMatrix = cam[].AdjustProjMatrix()
  glUseProgram(program)
  BindViewProjMatrix(program, viewMatrix, projMatrix)
  for id,mesh,trans,tex,mat in scene.walk(TMesh,TTransform,TImage,TMaterial):
    BindMaterial(program,mat[])
    var buffers = mEntFirstOpt[TObjectBuffers](id)
    var modMatrix = trans[].GenMatrix()
    BindModelMatrix(program, modMatrix)
    if buffers == nil:
      id.add(initObjectBuffers())
      buffers = mEntFirstOpt[TObjectBuffers](id)
      var meshBuf = CreateMeshBuffers(mesh[])
      buffers.vertex = meshBuf.vert
      buffers.index = meshBuf.index
      buffers.vao = CreateVertexAttribPtr(program)
      buffers.tex = CreateTexture(tex.data, tex.width, tex.height)
    AttachTextureToProgram(buffers.tex, program, 0, "tex")
    glBindVertexArray(buffers.vao)
    CheckError()
    glBindBuffer(GL_ARRAY_BUFFER.GLenum, buffers.vertex)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER.GLenum, buffers.index)
    CheckError()
    glDrawElements(GL_TRIANGLES, cast[GLSizei](mesh.indices.len), cGL_UNSIGNED_INT, nil)
    CheckError()


