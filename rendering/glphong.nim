import rendering.glshaders
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

proc RenderPhongLit*(scene: SceneId; meshEnt: var TComponent[TMesh]) {.procvar.} =

