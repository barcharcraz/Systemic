import phosphor
import ecs

var defVS = """
#version 140
in vec3 pos;
in vec3 norm;
in vec2 uv;
uniform MatrixBlock {
  mat4 mvp;
  mat4 world;
} mtx;

out vec2 uv0;
out vec3 norm0;
out vec3 worldPos0;
void main() {
  gl_Position = mtx.mvp * vec4(pos, 1.0);
  uv0 = uv;
  norm0 = (mtx.world * vec4(norm, 0.0)).xyz;
  worldPos0 = (mtx.world * vec4(pos, 1.0)).xyz;
}
"""
