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


"""