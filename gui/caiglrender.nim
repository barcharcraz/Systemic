import cairo
import opengl
import rendering/glcore
import ecs
import vecmath
var defVS = """
#version 140
in vec3 pos;
in vec2 uv;
out vec2 uv_out;
void main() {
  uv_out = uv;
  gl_position = vec4(pos, 1);
}
"""
var defPS = """
#version 140
uniform sampler2D tex;
in vec2 uv_out;
out vec4 outputColor;
void main() {
  outputColor = texture(tex, uv);
}
"""
type TUIObj = object
  pos: TVec3f
  uv: TVec2f
var defQuad: array[0..3, TUIObj]
defQuad[0].pos = initVec3f(-1, -1, 0)
defQuad[1].pos = initVec3f(1, -1, 0)
defQuad[2].pos = initVec3f(-1, 1, 0)
defQuad[3].pos = initVec3f(1, 1, 0)
defQuad[0].uv = initVec2f(0,0)
defQuad[1].uv = initVec2f(1,0)
defQuad[2].uv = initVec2f(0,1)
defQuad[3].uv = initVec2f(1,1)
var defIndex: array[0..5, uint32] = [0,1,2,1,3,2]
proc RenderUI*(context: PContext) {.procvar.} =
  var program {.global.}: GLuint
  var vs {.global.}: GLuint
  var ps {.global.}: GLuint
  var vbo {.global.}: GLuint
  var vao {.global.}: GLuint
  var index {.global.}: GLuint
  var tex {.global.}: GLuint
  if vs == 0: vs = CompileShader(GL_VERTEX_SHADER, defVS)
  if ps == 0: ps = CompileShader(GL_FRAGMENT_SHADER, defPS)
  if program == 0: program = CreateProgram(vs,ps)
  if vbo == 0 and index == 0:
    glGenBuffers(1, addr vbo)
    glGenBuffers(1, addr index)
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index)
    var vertSize: GLsizeiptr = sizeof(TUIObj) * defQuad.len
    var indexSize: GLsizeiptr = sizeof(uint32) * defIndex.len
    glBufferData(GL_ARRAY_BUFFER, vertSize, addr defQuad[0], GL_STATIC_DRAW)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexSize, addr defIndex[0], GL_STATIC_DRAW)
  if vao == 0:
    glGenVertexArrays(1, addr vao)
    glBindVertexArray(vao)
    var posLoc = glGetAttribLocation(program, "pos")
    var uvLoc = glGetAttribLocation(program, "uv")
    glEnableVertexAttribArray(posLoc.GLuint)
    glEnableVertexAttribArray(uvLoc.GLuint)
    glVertexAttribPointer(posLoc.GLuint, 3, cGL_FLOAT, false, sizeof(TUIObj).GLsizei, nil)
    glVertexAttribPointer(uvLoc.GLuint, 2, cGL_FLOAT, false, sizeof(TUIObj).GLsizei, cast[ptr GLvoid](sizeof(TVec3f)))
  var surf = get_group_target(context)
  var height = get_height(surf)
  var width = get_width(surf)
  if tex == 0:
    tex = InitializeTexture(
  glUseProgram(program)
