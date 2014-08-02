import opengl
type EAttribNameNotFound = object of ESynch
type EUnsupportedAttribType = object of ESynch
proc GetAttribInfo(program, attrib: GLuint): tuple[typ: GLenum, len: GLint] =
  glGetActiveAttrib(program, attrib, 0, nil, addr result.len, addr result.typ, nil)
  case result.typ
  of cGL_FLOAT:
    result.len = 1
    result.typ = cGL_FLOAT
  of GL_FLOAT_VEC2:
    result.len = 2
    result.typ = cGL_FLOAT
  of GL_FLOAT_VEC3:
    result.len = 3
    result.typ = cGL_FLOAT
  of GL_FLOAT_VEC4:
    result.len = 4
    result.typ = cGL_FLOAT
  else:
    raise newException(EUnsupportedAttribType, "attrib type " & repr(result.typ) & " not supported")
proc GetSizeOfGLType(typ: GLenum): int =
  case typ
  of cGL_FLOAT:
    return 4
  else:
    raise newException(EUnsupportedAttribType, "coudl not get type size")
proc SetUpAttribArray(program, vao, verts, indices: GLuint; typ: typedesc) =
  var typInst: ptr typ = cast[ptr typ](nil)
  glBindVertexArray(vao)
  glBindBuffer(GL_ARRAY_BUFFER, verts)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indices)
  var attribIdx = 0
  var attribLoc: GLint = -1
  for name, val in fieldPairs(typInst[]):
    glEnableVertexAttribArray(attribIdx)
    attribLoc = glGetAttribLocation(program, name)
    if attribLoc == -1: 
      raise newException(EAttribNameNotFound, name & " is not an attrib in the program")
    var (typ, len) = GetAttribInfo(program, attribLoc)
    assert(sizeof(val) == GetSizeOfGLType(typ) * len)
    glVertexAttribPointer(attribLoc, len, typ, GL_FALSE, sizeof(typ), cast[pointer](addr val))

proc CreateShaderInputs*[T,U](program: GLuint; verts: openarray[T]; indices: openarray[U]): tuple[vao, verts, indices: GLuint] =
  glGenBuffers(1, addr result.verts)
  glGenBuffers(1, addr result.indices)
  glBindBuffer(GL_ARRAY_BUFFER, result.verts)
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, result.indices)
  var vertSize = sizeof(T) * verts.len
  var idxSize = sizeof(U) * indices.len
  glBufferData(GL_ARRAY_BUFFER, vertSize.GLsizeiptr, addr verts[0], GL_STATIC_DRAW)
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, idxSize.GLsizeiptr, addr indices[0], GL_STATIC_DRAW)
  glGenVertexArrays(1, addr result.vao)
  SetUpAttribArray(program, result.vao, result.verts, result.indices, T)
