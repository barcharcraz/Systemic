import rendering.glshaders
import glcore
import ecs
import opengl

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
out vec3 view_pos;
out vec2 uv_out;

void main() {
    uv_out = uv;
    mat4 modelviewproj = mvp.proj * mvp.view * mvp.model;
    mat4 modelview = mvp.view * mvp.model;
    gl_Position = modelviewproj * vec4(pos, 1)
    view_pos = modelview * vec4(pos, 1)
    norm_out = mat3(modelview) * norm
}
"""
var defPS = LightStructs & ForwardLighting & """
in vec3 norm_out;
in vec3 view_pos;
in vec2 uv_out;
out vec4 outputColor;
uniform directionalLight_t dlights[NUM_DIRECTIONAL];
uniform material_t mat;
uniform sampler2D tex;
void main() {
  outputColor = mat.ambiant;
  
  for(int i = 0; i < NUM_DIRECTIONAL; ++i) {
    outputColor += directionalLight(dlights[i], normal, viewPos, mat);
  }
  outputColor = clamp(outputColor, 0.0, 1.0)
  outputColor = outputColor * texture(tex, vec2(uvout.x, 1 - uvout.y));
}

"""

proc RenderPhongLit*(scene: SceneId) {.procvar.} =
  var program {.global.}: GLuint
  var ps {.global.}: GLuint
  var vs {.global.}: GLuint
  var dlights = addr components(scene, TComponent[TDirectionalLight)
  if vs == 0 or ps == 0:
    var def = genDefine("NUM_DIRECTIONAL", dlights.len)
    vs = CompileShader(GL_VERTEX_SHADER, def & defVS)
    ps = CompileShader(GL_FRAGMENT_SHADER, def & defPS)
    program = CreateProgram(vs, ps)
  var (cam, camTrans) = entComponents(scene, TCamera, TTransform)
  var viewMatrix = camTrans.GenMatrix().AdjustViewMatrix()
  var projMatrix = cam.AdjustProjMatrix()
  glUseProgram(program)
  BindViewProjMatrix(program, view, proj)
  for id,mesh,trans,tex,mat in scene.walk(TMesh,TTransform,TImage,TMaterial):
    var buffers = mEntFirstOpt[TObjectBuffers(id)
    if buffers == nil:
      id.add(initObjectBuffers)
      buffers = mEntFirstOpt[TObjectBuffers](id)
      buffers.vert, buffers.index = CreateMeshBuffers(mesh)
      buffers.vao = CreateVertexAttribPtr(program)
      buffers.tex = CreateTexture(tex.data, tex.width, tex.height)
    AttachTextureToProgram(buffers.tex, program, 0, "tex")
    glBindVertexArray(buffers.vao)
    CheckError()
    glBindBuffer(GL_ARRAY_BUFFER.GLenum, buffers.vertex)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER.GLenum, buffers.index)
    CheckError()
    glDrawElements(GL_TRIANGLES, cast[GLSizei](mesh.indices.length), cGL_UNSIGNED_INT, nil)
    CheckError()

