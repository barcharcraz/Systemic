import cairo
import opengl
import rendering/glcore
import ecs
import unsigned
import vecmath
var defVS = """
#version 140
in vec3 pos;
in vec2 uv;
out vec2 uv_out;
void main() {
  uv_out = uv;
  gl_Position = vec4(pos, 1);
}
"""
var defPS = """
#version 140
uniform sampler2D tex;
in vec2 uv_out;
out vec4 outputColor;
void main() {
  vec4 texel = texture(tex, uv_out);
  if(texel.a < 0.5) {
    discard;
  }
  outputColor = texel;
}
"""
type TUIObj = object
  pos: TVec3f
  uv: TVec2f
var defQuad: array[0..3, TUIObj]
defQuad[0].pos = vec3f(-1, -1, 0)
defQuad[1].pos = vec3f(1, -1, 0)
defQuad[2].pos = vec3f(-1, 1, 0)
defQuad[3].pos = vec3f(1, 1, 0)
defQuad[0].uv = vec2f(0,1)
defQuad[1].uv = vec2f(1,1)
defQuad[2].uv = vec2f(0,0)
defQuad[3].uv = vec2f(1,0)
var defIndex: array[0..5, uint32] = [0.uint32,1.uint32,2.uint32,1.uint32,3.uint32,2.uint32]
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
  glUseProgram(program)
  if vbo == 0 and index == 0:
    glGenBuffers(1, addr vbo)
    glGenBuffers(1, addr index)
    glBindBuffer(GL_ARRAY_BUFFER, vbo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index)
    var vertSize = sizeof(TUIObj) * defQuad.len
    var indexSize = sizeof(uint32) * defIndex.len
    glBufferData(GL_ARRAY_BUFFER, vertSize.GLsizeiptr, addr defQuad[0], GL_STATIC_DRAW)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexSize.GLsizeiptr, addr defIndex[0], GL_STATIC_DRAW)
  if vao == 0:
    glGenVertexArrays(1, addr vao)
    glBindVertexArray(vao)
    var posLoc = glGetAttribLocation(program, "pos")
    var uvLoc = glGetAttribLocation(program, "uv")
    glEnableVertexAttribArray(posLoc.GLuint)
    glEnableVertexAttribArray(uvLoc.GLuint)
    glVertexAttribPointer(posLoc.GLuint, 3, cGL_FLOAT, false, sizeof(TUIObj).GLsizei, nil)
    glVertexAttribPointer(uvLoc.GLuint, 2, cGL_FLOAT, false, sizeof(TUIObj).GLsizei, cast[pointer](sizeof(TVec3f)))
  var surf = get_group_target(context)
  var height = get_height(surf)
  var width = get_width(surf)
  var data = get_data(surf)
  if tex == 0:
    tex = InitializeTexture(width, height, 1)
    glBindTexture(GL_TEXTURE_2D, tex)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
  glBindTexture(GL_TEXTURE_2D, tex)
  glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width.GLsizei, height.GLsizei, GL_BGRA, cGL_UNSIGNED_BYTE, cast[pointer](data))
  # we have copied our cairo memory buffer to openGL, we can not clear the cairo buffer
  context.set_operator(OPERATOR_CLEAR)
  context.paint()
  context.set_operator(OPERATOR_OVER)
  AttachTextureToProgram(tex, program, 0, "tex")
  glBindVertexArray(vao)
  glBindBuffer(GL_ARRAY_BUFFER, vbo)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index)
  # we could probably use something smaller than an int here, but who the hell knows
  # MELOPT
  glDrawElements(GL_TRIANGLES, cast[GLSizei](defIndex.len), GL_UNSIGNED_INT, nil)
  CheckError()
