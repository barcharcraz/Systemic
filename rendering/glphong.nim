import opengl
import glshaders
import glcore
import genutils
import ecs
import components
import unsigned
import logging
import vecmath
import utils/iterators
var defVS = """
struct matrices_t {
    mat4 model;
    mat4 view;
    mat4 proj;
};
uniform matrices_t mvp;
uniform mat4 shadowVP;
in vec3 pos;
in vec3 norm;
in vec2 uv;
out vec3 norm_out;
out vec3 view_pos;
out vec2 uv_out;
out vec4 shadowPos;
void main() {
    uv_out = uv;
    mat4 modelviewproj = mvp.proj * mvp.view * mvp.model;
    mat4 modelview = mvp.view * mvp.model;
    gl_Position = modelviewproj * vec4(pos, 1);
    view_pos = (modelview * vec4(pos,1)).xyz;
    //taking the transpose on the GPU like this is likely NOT
    //a very good idea, it is in the VS so meh but still.
    //also this breaks for non-uniform scaleing.
    norm_out = mat3(modelview) * norm;
    shadowPos = shadowVP * mvp.model * vec4(pos, 1);
}
"""
var version = "#version 140\n"
var defPS = """
""" & LightStructs & ForwardLighting & """
in vec3 norm_out;
in vec3 view_pos;
in vec2 uv_out;
in vec4 shadowPos;
out vec4 outputColor;
layout(std140) uniform dlightBlock {
  directionalLight_t dlights[NUM_DIRECTIONAL + 1];
};
layout(std140) uniform plightBlock {
  pointLight_t plights[NUM_POINT + 1];
};
uniform material_t mat;
uniform sampler2D tex;
uniform sampler2DShadow shad;
void main() {
  outputColor = mat.ambiant;
  float visib = 1.0f
  if (texture(shad, shadowPos.xy).z < shadowPos.z) {
    visib = 0.5f
  }
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
proc ConstructBiasMatrix(
proc RenderPhongLit*(scene: SceneId) {.procvar.} =
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var dlightsUniform {.global.}: GLuint
  var plightsUniform {.global.}: GLuint
  #var dlights = GetDefaultNode[TDirectionalLight]().sceneList[scene.int]
  
  var (camEnt, cam, camTrans) = first(walk(scene, TCamera, TTransform))
  var viewMatrix = camTrans[].GenRotTransMatrix().AdjustViewMatrix()
  var projMatrix = cam[].AdjustProjMatrix()
  
  var dlights = CollectDirLights(scene, viewMatrix)
  var plights = CollectPointLights(scene, viewMatrix)
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
  else:
    UpdateUniformBuffer(dlightsUniform, dlights)
  if plightsUniform == 0:
    plightsUniform = CreateUniformBuffer(plights)
    glUniformBlockBinding(program, plightsIdx, 1)
  else:
    UpdateUniformBuffer(plightsUniform, plights)
  glBindBufferBase(GL_UNIFORM_BUFFER, 0, dlightsUniform)
  glBindBufferBase(GL_UNIFORM_BUFFER, 1, plightsUniform)
  glUseProgram(program)
  BindViewProjMatrix(program, viewMatrix, projMatrix)
  for id,mesh,trans,tex,mat in scene.walk(TMesh,TTransform,TImage,TMaterial):
    BindMaterial(program,mat[])
    var buffers = id?TObjectBuffers
    var modMatrix = trans[].GenMatrix()
    BindModelMatrix(program, modMatrix)
    if buffers == nil:
      id.add(initObjectBuffers())
      buffers = id?TObjectBuffers
      var meshBuf = CreateMeshBuffers(mesh[])
      buffers.vertex = meshBuf.vert
      buffers.index = meshBuf.index
      buffers.vao = CreateVertexAttribPtr(program, buffers.vertex, buffers.index)
      buffers.tex = CreateTexture(tex.data, tex.width, tex.height)
    AttachTextureToProgram(buffers.tex, program, 0, "tex")
    glBindVertexArray(buffers.vao)
    #glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers.index)
    glDrawElements(GL_TRIANGLES, cast[GLSizei](mesh.indices.len), GL_UNSIGNED_INT, nil)
    glBindVertexArray(0)


